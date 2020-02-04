package com.google.devtools.coverageoutputgenerator;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.ImmutableMap;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static com.google.devtools.coverageoutputgenerator.Constants.GCOV_EXTENSION;
import static com.google.devtools.coverageoutputgenerator.Constants.PROFDATA_EXTENSION;
import static com.google.devtools.coverageoutputgenerator.Constants.TRACEFILE_EXTENSION;
import static java.nio.charset.StandardCharsets.UTF_8;
import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;

/**
 * <p>A copy of {@link Main} which instead uses the SonarQubeCoverageReportPrinter
 * to emit a SonarQube 'Generic Test Coverage' XML format report.</p>
 * <p>This is located in the <code>com.google.devtools.coverageoutputgenerator</code>
 * package to take advantage of package-private Bazel classes.</p>
 *
 * @see <a>https://docs.sonarqube.org/latest/analysis/generic-test/</a>
 */
public class SonarQubeCoverageGenerator {
    private static final Logger logger = Logger.getLogger(SonarQubeCoverageGenerator.class.getName());

    public static void main(String[] args) {
        LcovMergerFlags flags = null;
        try {
            flags = LcovMergerFlags.parseFlags(args);
        } catch (IllegalArgumentException e) {
            logger.log(Level.SEVERE, e.getMessage());
            System.exit(1);
        }

        File outputFile = new File(flags.outputFile());

        List<File> filesInCoverageDir =
                flags.coverageDir() != null
                        ? getCoverageFilesInDir(flags.coverageDir())
                        : Collections.emptyList();
        Coverage coverage =
                Coverage.merge(
                        parseFiles(getTracefiles(flags, filesInCoverageDir), LcovParser::parse),
                        parseFiles(getGcovInfoFiles(filesInCoverageDir), GcovParser::parse));

        if (flags.sourcesToReplaceFile() != null) {
            coverage.maybeReplaceSourceFileNames(getMapFromFile(flags.sourcesToReplaceFile()));
        }

        File profdataFile = getProfdataFileOrNull(filesInCoverageDir);
        if (coverage.isEmpty()) {
            int exitStatus = 0;
            if (profdataFile == null) {
                logger.log(Level.WARNING, "There was no coverage found.");
                exitStatus = 0;
            } else {
                // Bazel doesn't support yet converting profdata files to lcov. We still want to output a
                // coverage report so we copy the content of the profdata file to the output file. This is
                // not ideal but it unblocks some Bazel C++
                // coverage users.
                // TODO(#5881): Add support for profdata files.
                try {
                    Files.copy(profdataFile.toPath(), outputFile.toPath(), REPLACE_EXISTING);
                } catch (IOException e) {
                    logger.log(
                            Level.SEVERE,
                            "Could not copy file "
                                    + profdataFile.getName()
                                    + " to output file "
                                    + outputFile.getName()
                                    + " due to: "
                                    + e.getMessage());
                    exitStatus = 1;
                }
            }
            System.exit(exitStatus);
        }

        if (!coverage.isEmpty() && profdataFile != null) {
            // If there is one profdata file then there can't be other types of reports because there is
            // no way to merge them.
            // TODO(#5881): Add support for profdata files.
            logger.log(
                    Level.WARNING,
                    "Bazel doesn't support LLVM profdata coverage amongst other coverage formats.");
            System.exit(0);
        }

        if (!flags.filterSources().isEmpty()) {
            coverage = Coverage.filterOutMatchingSources(coverage, flags.filterSources());
        }

        if (flags.hasSourceFileManifest()) {
            // The source file manifest is only required for C++ code coverage.
            Set<String> ccSources = getCcSourcesFromSourceFileManifest(flags.sourceFileManifest());
            if (!ccSources.isEmpty()) {
                // Only filter out coverage if there were C++ sources found in the coverage manifest.
                coverage = Coverage.getOnlyTheseCcSources(coverage, ccSources);
            }
        }

        if (coverage.isEmpty()) {
            logger.log(Level.WARNING, "There was no coverage found.");
            System.exit(0);
        }

        int exitStatus = 0;

        try {
            SonarQubeCoverageReportPrinter.print(new FileOutputStream(outputFile), coverage);
        } catch (IOException e) {
            logger.log(
                    Level.SEVERE,
                    "Could not write to output file " + outputFile + " due to " + e.getMessage());
            exitStatus = 1;
        }
        System.exit(exitStatus);
    }

    /**
     * Returns a set of source file names from the given manifest.
     *
     * <p>The manifest contains file names line by line. Each file can either be a source file (e.g.
     * .java, .cc) or a coverage metadata file (e.g. .gcno, .em).
     *
     * <p>This method only returns the C++ source files, ignoring the other files as they are not
     * necessary when putting together the final coverage report.
     */
    private static Set<String> getCcSourcesFromSourceFileManifest(String sourceFileManifest) {
        Set<String> sourceFiles = new HashSet<>();
        try (FileInputStream inputStream = new FileInputStream(new File(sourceFileManifest));
             InputStreamReader inputStreamReader = new InputStreamReader(inputStream, UTF_8);
             BufferedReader reader = new BufferedReader(inputStreamReader)) {
            for (String line = reader.readLine(); line != null; line = reader.readLine()) {
                if (!isMetadataFile(line) && isCcFile(line)) {
                    sourceFiles.add(line);
                }
            }
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Error reading file " + sourceFileManifest + ": " + e.getMessage());
        }
        return sourceFiles;
    }

    private static boolean isMetadataFile(String filename) {
        return filename.endsWith(".gcno") || filename.endsWith(".em");
    }

    private static boolean isCcFile(String filename) {
        return filename.endsWith(".cc") || filename.endsWith(".c") || filename.endsWith(".cpp")
                || filename.endsWith(".hh") || filename.endsWith(".h") || filename.endsWith(".hpp");
    }

    private static List<File> getGcovInfoFiles(List<File> filesInCoverageDir) {
        List<File> gcovFiles = getFilesWithExtension(filesInCoverageDir, GCOV_EXTENSION);
        if (gcovFiles.isEmpty()) {
            logger.log(Level.INFO, "No gcov info file found.");
        } else {
            logger.log(Level.INFO, "Found " + gcovFiles.size() + " gcov info files.");
        }
        return gcovFiles;
    }

    /**
     * Returns a .profdata file from the given files or null if none or more profdata files were
     * found.
     */
    private static File getProfdataFileOrNull(List<File> files) {
        List<File> profdataFiles = getFilesWithExtension(files, PROFDATA_EXTENSION);
        if (profdataFiles.isEmpty()) {
            logger.log(Level.INFO, "No .profdata file found.");
            return null;
        }
        if (profdataFiles.size() > 1) {
            logger.log(
                    Level.SEVERE,
                    "Bazel currently supports only one profdata file per test. "
                            + profdataFiles.size()
                            + " .profadata files were found instead.");
            return null;
        }
        logger.log(Level.INFO, "Found one .profdata file.");
        return profdataFiles.get(0);
    }

    private static List<File> getTracefiles(LcovMergerFlags flags, List<File> filesInCoverageDir) {
        List<File> lcovTracefiles = new ArrayList<>();
        if (flags.coverageDir() != null) {
            lcovTracefiles = getFilesWithExtension(filesInCoverageDir, TRACEFILE_EXTENSION);
        } else if (flags.reportsFile() != null) {
            lcovTracefiles = getTracefilesFromFile(flags.reportsFile());
        }
        if (lcovTracefiles.isEmpty()) {
            logger.log(Level.INFO, "No lcov file found.");
        } else {
            logger.log(Level.INFO, "Found " + lcovTracefiles.size() + " tracefiles.");
        }
        return lcovTracefiles;
    }

    /**
     * Reads the content of the given file and returns a matching map.
     *
     * <p>It assumes the file contains lines in the form key:value. For each line it creates an entry
     * in the map with the corresponding key and value.
     */
    private static ImmutableMap<String, String> getMapFromFile(String file) {
        ImmutableMap.Builder<String, String> mapBuilder = ImmutableMap.builder();

        try (FileInputStream inputStream = new FileInputStream(file);
             InputStreamReader inputStreamReader = new InputStreamReader(inputStream, UTF_8);
             BufferedReader reader = new BufferedReader(inputStreamReader)) {
            for (String keyToValueLine = reader.readLine();
                 keyToValueLine != null;
                 keyToValueLine = reader.readLine()) {
                String[] keyAndValue = keyToValueLine.split(":");
                if (keyAndValue.length == 2) {
                    mapBuilder.put(keyAndValue[0], keyAndValue[1]);
                }
            }
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Error reading file " + file + ": " + e.getMessage());
        }
        return mapBuilder.build();
    }

    private static Coverage parseFiles(List<File> files, Parser parser) {
        Coverage coverage = new Coverage();
        for (File file : files) {
            try {
                logger.log(Level.INFO, "Parsing file " + file.toString());
                List<SourceFileCoverage> sourceFilesCoverage = parser.parse(new FileInputStream(file));
                for (SourceFileCoverage sourceFileCoverage : sourceFilesCoverage) {
                    coverage.add(sourceFileCoverage);
                }
            } catch (IOException e) {
                logger.log(
                        Level.SEVERE,
                        "File " + file.getAbsolutePath() + " could not be parsed due to: " + e.getMessage());
                System.exit(1);
            }
        }
        return coverage;
    }

    /**
     * Returns a list of all the files with the given extension found recursively under the given dir.
     */
    @VisibleForTesting
    static List<File> getCoverageFilesInDir(String dir) {
        List<File> files = new ArrayList<>();
        try (Stream<Path> stream = Files.walk(Paths.get(dir))) {
            files =
                    stream
                            .filter(
                                    p ->
                                            p.toString().endsWith(TRACEFILE_EXTENSION)
                                                    || p.toString().endsWith(GCOV_EXTENSION)
                                                    || p.toString().endsWith(PROFDATA_EXTENSION))
                            .map(path -> path.toFile())
                            .collect(Collectors.toList());
        } catch (IOException ex) {
            logger.log(Level.SEVERE, "Error reading folder " + dir + ": " + ex.getMessage());
        }
        return files;
    }

    static List<File> getFilesWithExtension(List<File> files, String extension) {
        return files.stream()
                .filter(file -> file.toString().endsWith(extension))
                .collect(Collectors.toList());
    }

    static List<File> getTracefilesFromFile(String reportsFile) {
        List<File> datFiles = new ArrayList<>();
        try (FileInputStream inputStream = new FileInputStream(reportsFile)) {
            InputStreamReader inputStreamReader = new InputStreamReader(inputStream, UTF_8);
            BufferedReader reader = new BufferedReader(inputStreamReader);
            for (String tracefile = reader.readLine(); tracefile != null; tracefile = reader.readLine()) {
                // TODO(elenairina): baseline coverage contains some file names that need to be modified
                if (!tracefile.endsWith("baseline_coverage.dat")) {
                    datFiles.add(new File(tracefile));
                }
            }

        } catch (IOException e) {
            logger.log(Level.SEVERE, "Error reading file " + reportsFile + ": " + e.getMessage());
        }
        return datFiles;
    }

}