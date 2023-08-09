"""
Rules to analyse Bazel projects with SonarQube.
"""

load("@bazel_version//:bazel_version.bzl", "bazel_version")
load("@bazel_skylib//lib:versions.bzl", "versions")

def sonarqube_coverage_generator_binary(name = None):
    if versions.is_at_least(threshold = "2.1.0", version = bazel_version):
        deps = ["@remote_coverage_tools//:all_lcov_merger_lib"]
    else:
        deps = ["@bazel_tools//tools/test/CoverageOutputGenerator/java/com/google/devtools/coverageoutputgenerator:all_lcov_merger_lib"]

    native.java_binary(
        name = "SonarQubeCoverageGenerator",
        srcs = [
            "src/main/java/com/google/devtools/coverageoutputgenerator/SonarQubeCoverageGenerator.java",
            "src/main/java/com/google/devtools/coverageoutputgenerator/SonarQubeCoverageReportPrinter.java",
        ],
        main_class = "com.google.devtools.coverageoutputgenerator.SonarQubeCoverageGenerator",
        deps = deps,
    )

TargetInfo = provider(
    fields = {
        "deps": "depset of targets",
    }
)

SqProjectInfo = provider(
    fields = {
        "srcs": "main sources",
        "test_srcs": "test sources",
    }
)

def _test_targets_aspect_impl(target, ctx):
    transitive = []
    direct = []

    if ctx.rule.kind.endswith("_test"):
        direct.append(target)

    if hasattr(ctx.rule.attr, 'tests'):
        for dep in ctx.rule.attr.tests:
            transitive.append(dep[TargetInfo].deps)

    return TargetInfo(deps=depset(direct=direct, transitive=transitive))

# This aspect is for collecting test targets from test_suite rules
# to save some duplication in the BUILD files.
test_targets_aspect = aspect(
    implementation = _test_targets_aspect_impl,
    attr_aspects = [ 'tests' ],
)

def _build_sonar_project_properties(ctx, sq_properties_file, rule):
    module_path = ctx.build_file_path.replace("/BUILD.bazel", "/").replace("/BUILD", "/")
    depth = len(module_path.split("/")) - 1
    if rule == 'sq_project':
        parent_path = "../" * depth
    else:
        parent_path = ""

    # SonarQube requires test reports to be named like TEST-foo.xml, so we step
    # through `test_targets` to find the matching `test_reports` values, and
    # symlink them to the usable name

    if hasattr(ctx.attr, "test_targets") and ctx.attr.test_targets and hasattr(ctx.attr, "test_reports") and ctx.attr.test_reports and ctx.files.test_reports:
        test_reports_path = module_path + "test-reports"
        if rule == 'sq_project':
            local_test_reports_path = module_path + "test-reports"
        else:
            local_test_reports_path = "test-reports"
        test_reports_runfiles = []

        inc = 0
        for dep in ctx.attr.test_targets:
            if TargetInfo in dep:
                for t in dep[TargetInfo].deps.to_list():
                    test_target = t.label
                    bazel_test_report_path = "bazel-testlogs/" + test_target.package + "/" + test_target.name + "/test.xml"
                    matching_test_reports = [t for t in ctx.files.test_reports if t.short_path == bazel_test_report_path]
                    if matching_test_reports:
                        bazel_test_report = matching_test_reports[0]
                        sq_test_report = ctx.actions.declare_file("%s/TEST-%s.xml" % (local_test_reports_path, inc))
                        ctx.actions.symlink(
                            output = sq_test_report,
                            target_file = bazel_test_report,
                        )
                        test_reports_runfiles.append(sq_test_report)
                        inc += 1
                    else:
                        print("Expected Bazel test report for %s with path %s" % (test_target, bazel_test_report_path))

    else:
        test_reports_path = ""
        test_reports_runfiles = []

    if hasattr(ctx.attr, "coverage_report") and ctx.attr.coverage_report:
        coverage_report_path = parent_path + ctx.file.coverage_report.short_path
        coverage_runfiles = [ctx.file.coverage_report]
    else:
        coverage_report_path = ""
        coverage_runfiles = []

    java_files = _get_java_files([t for t in ctx.attr.targets if t[JavaInfo]])

    ctx.actions.expand_template(
        template = ctx.file.sq_properties_template,
        output = sq_properties_file,
        substitutions = {
            "{PROJECT_KEY}": ctx.attr.project_key,
            "{PROJECT_NAME}": ctx.attr.project_name,
            "{SOURCES}": ",".join([parent_path + f.short_path for f in ctx.files.srcs]),
            "{TEST_SOURCES}": ",".join([parent_path + f.short_path for f in ctx.files.test_srcs]),
            "{SOURCE_ENCODING}": ctx.attr.source_encoding,
            "{JAVA_BINARIES}": ",".join([parent_path + j.short_path for j in java_files["output_jars"].to_list()]),
            "{JAVA_LIBRARIES}": ",".join([parent_path + j.short_path for j in java_files["deps_jars"].to_list()]),
            "{MODULES}": ",".join(ctx.attr.modules.values()),
            "{TEST_REPORTS}": test_reports_path,
            "{COVERAGE_REPORT}": coverage_report_path,
        },
        is_executable = False,
    )

    return ctx.runfiles(
        files = [sq_properties_file] + ctx.files.srcs + ctx.files.test_srcs + test_reports_runfiles + coverage_runfiles,
        transitive_files = depset(transitive = [java_files["output_jars"], java_files["deps_jars"]]),
    )

def _get_java_files(java_targets):
    return {
        "output_jars": depset(direct = [j.class_jar for t in java_targets for j in t[JavaInfo].outputs.jars]),
        "deps_jars": depset(transitive = [t[JavaInfo].transitive_deps for t in java_targets] + [t[JavaInfo].transitive_runtime_deps for t in java_targets]),
    }

def _test_report_path(parent_path, test_target):
    return parent_path + "bazel-testlogs/" + test_target.package + "/" + test_target.name

_sonarqube_template = """
#!/bin/bash

set -e

echo 'Dereferencing bazel runfiles symlinks for accurate SCM resolution...'

for f in {srcs} {test_srcs}
do
    mkdir -p $(dirname orig/$f)
    mv $f orig/$f
    cp -L orig/$f $f
done

echo '... done.'

{sonar_scanner} ${{1+"$@"}} -Dproject.settings={sq_properties_file}

echo 'Restoring original bazel runfiles symlinks...'
for f in {srcs} {test_srcs}
do
    rm $f
    mv orig/$f $f
done
rm -rf orig
echo '... done.'
"""

def _sonarqube_impl(ctx):
    sq_properties_file = ctx.actions.declare_file("sonar-project.properties")

    local_runfiles = _build_sonar_project_properties(ctx, sq_properties_file, 'sonarqube')

    module_runfiles = ctx.runfiles(files = [])
    for module in ctx.attr.modules.keys():
        module_runfiles = module_runfiles.merge(module[DefaultInfo].default_runfiles)

    src_paths=[]
    for t in ctx.attr.srcs:
        for f in t[DefaultInfo].files.to_list():
            src_paths.append(f.short_path)

    test_src_paths=[]
    for t in ctx.attr.test_srcs:
        for f in t[DefaultInfo].files.to_list():
            test_src_paths.append(f.short_path)

    for module in ctx.attr.modules.keys():
        for t in module[SqProjectInfo].srcs:
            for f in t[DefaultInfo].files.to_list():
                src_paths.append(f.short_path)

        for t in module[SqProjectInfo].test_srcs:
            for f in t[DefaultInfo].files.to_list():
                test_src_paths.append(f.short_path)

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = _sonarqube_template.format(
            sq_properties_file=sq_properties_file.short_path,
            sonar_scanner = ctx.executable.sonar_scanner.short_path,
            srcs = ' '.join(src_paths),
            test_srcs = ' '.join(test_src_paths),
        ),
        is_executable = True,
    )

    return [DefaultInfo(
        runfiles = ctx.runfiles(files = [ctx.executable.sonar_scanner] + ctx.files.scm_info).merge(ctx.attr.sonar_scanner[DefaultInfo].default_runfiles).merge(local_runfiles).merge(module_runfiles),
    )]


_COMMON_ATTRS = dict(dict(), **{
    "project_key": attr.string(mandatory = True),
    "project_name": attr.string(),
    "srcs": attr.label_list(allow_files = True, default = []),
    "source_encoding": attr.string(default = "UTF-8"),
    "targets": attr.label_list(default = []),
    "modules": attr.label_keyed_string_dict(default = {}),
    "test_srcs": attr.label_list(allow_files = True, default = []),
    "test_targets": attr.label_list(default = [], aspects = [ test_targets_aspect ]),
    "test_reports": attr.label_list(allow_files = True, default = []),
    "sq_properties_template": attr.label(allow_single_file = True, default = "@bazel_sonarqube//:sonar-project.properties.tpl"),
    "sq_properties": attr.output(),
})

_sonarqube = rule(
    attrs = dict(_COMMON_ATTRS, **{
        "coverage_report": attr.label(allow_single_file = True, mandatory = False),
        "scm_info": attr.label_list(allow_files = True),
        "sonar_scanner": attr.label(executable = True, default = "@bazel_sonarqube//:sonar_scanner", cfg = "host"),
    }),
    fragments = ["jvm"],
    host_fragments = ["jvm"],
    implementation = _sonarqube_impl,
    executable = True,
)

def sonarqube(
        name,
        project_key,
        scm_info,
        coverage_report = None,
        project_name = None,
        srcs = [],
        source_encoding = None,
        targets = [],
        test_srcs = [],
        test_targets = [],
        test_reports = [],
        modules = {},
        sonar_scanner = "@bazel_sonarqube//:sonar_scanner",
        sq_properties_template = "@bazel_sonarqube//:sonar-project.properties.tpl",
        tags = [],
        visibility = [],
        **kwargs):
    """A runnable rule to execute SonarQube analysis.

    Generates `sonar-project.properties` and invokes the SonarScanner CLI tool
    to perform the analysis.

    Args:
        name: Name of the target.
        project_key: SonarQube project key, e.g. `com.example.project:module`.
        scm_info: Source code metadata. For example, to include Git data from
            the workspace root, create a filegroup:

            `filegroup(name = "git_info", srcs = glob([".git/**"], exclude = [".git/**/*[*"]))`

            and reference it as `scm_info = [":git_info"],`.
        coverage_report: Coverage file in SonarQube generic coverage report
            format. This can be created using the generator from this project
            (see the README for example usage).
        project_name: SonarQube project display name.
        srcs: Project sources to be analysed by SonarQube.
        source_encoding: Source file encoding.
        targets: Bazel targets to be analysed by SonarQube.

            These may be used to provide additional provider information to the
            SQ analysis , e.g. Java classpath context.
        modules: Sub-projects to associate with this SonarQube project, i.e.
            `sq_project` targets.
        test_srcs: Project test sources to be analysed by SonarQube. This must
            be set along with `test_reports` and `test_sources` for accurate
            test reporting.
        test_targets: A list of test targets relevant to the SQ project. This
            will be used with the `test_reports` attribute to generate the
            report paths in sonar-project.properties.
        test_reports: Targets describing Junit-format execution reports. May be
            configured in the workspace root to use Bazel's execution reports
            as below:

            `filegroup(name = "test_reports", srcs = glob(["bazel-testlogs/**/test.xml"]))`


            and referenced as `test_reports = [":test_reports"],`.

            **Note:** this requires manually executing `bazel test` or `bazel
            coverage` before running the `sonarqube` target.
        sonar_scanner: Bazel binary target to execute the SonarQube CLI Scanner.
        sq_properties_template: Template file for `sonar-project.properties`.
        tags: Bazel target tags, e.g. `["manual"]`.
        visibility: Bazel target visibility, e.g. `["//visibility:public"]`.
    """
    _sonarqube(
        name = name,
        project_key = project_key,
        project_name = project_name,
        scm_info = scm_info,
        srcs = srcs,
        source_encoding = source_encoding,
        targets = targets,
        modules = modules,
        test_srcs = test_srcs,
        test_targets = test_targets,
        test_reports = test_reports,
        coverage_report = coverage_report,
        sonar_scanner = sonar_scanner,
        sq_properties_template = sq_properties_template,
        sq_properties = "sonar-project.properties",
        tags = tags,
        visibility = visibility,
        **kwargs,
    )

def _sq_project_impl(ctx):
    local_runfiles = _build_sonar_project_properties(ctx, ctx.outputs.sq_properties, 'sq_project')
    
    return [DefaultInfo(
        runfiles = local_runfiles,
    ), SqProjectInfo(
        srcs = ctx.attr.srcs,
        test_srcs = ctx.attr.test_srcs,
    )]

_sq_project = rule(
    attrs = _COMMON_ATTRS,
    implementation = _sq_project_impl,
)

def sq_project(
        name,
        project_key,
        project_name = None,
        srcs = [],
        source_encoding = None,
        targets = [],
        test_srcs = [],
        test_targets = [],
        test_reports = [],
        modules = {},
        sq_properties_template = "@bazel_sonarqube//:sonar-project.properties.tpl",
        tags = [],
        visibility = [],
        **kwargs):
    """A configuration rule to generate SonarQube analysis properties.

    Targets of this type may be referenced by the [`modules`](#sonarqube-modules)
    attribute of the `sonarqube` rule, to create a multi-module SonarQube
    project.

    Args:
        name: Name of the target.
        project_key: SonarQube project key, e.g. `com.example.project:module`.
        project_name: SonarQube project display name.
        srcs: Project sources to be analysed by SonarQube.
        source_encoding: Source file encoding.
        targets: Bazel targets to be analysed by SonarQube.

            These may be used to provide additional provider information to the
            SQ analysis , e.g. Java classpath context.
        modules: Sub-projects to associate with this SonarQube project, i.e.
            `sq_project` targets.
        test_srcs: Project test sources to be analysed by SonarQube. This must
            be set along with `test_reports` and `test_sources` for accurate
            test reporting.
        test_targets: A list of test targets relevant to the SQ project. This
            will be used with the `test_reports` attribute to generate the
            report paths in sonar-project.properties.
        test_reports: Targets describing Junit-format execution reports. May be
            configured in the workspace root to use Bazel's execution reports
            as below:

            `filegroup(name = "test_reports", srcs = glob(["bazel-testlogs/**/test.xml"]))`


            and referenced as `test_reports = [":test_reports"],`.

            **Note:** this requires manually executing `bazel test` or `bazel
            coverage` before running the `sonarqube` target.
        sq_properties_template: Template file for `sonar-project.properties`.
        tags: Bazel target tags, e.g. `["manual"]`.
        visibility: Bazel target visibility, e.g. `["//visibility:public"]`.
    """
    _sq_project(
        name = name,
        project_key = project_key,
        project_name = project_name,
        srcs = srcs,
        test_srcs = test_srcs,
        source_encoding = source_encoding,
        targets = targets,
        test_targets = test_targets,
        test_reports = test_reports,
        modules = modules,
        sq_properties_template = sq_properties_template,
        sq_properties = "sonar-project.properties",
        tags = tags,
        visibility = visibility,
        **kwargs,
    )
