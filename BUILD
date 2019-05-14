java_binary(
    name = "SonarQubeCoverageGenerator",
    srcs = [
        "src/main/java/com/google/devtools/coverageoutputgenerator/SonarQubeCoverageGenerator.java",
        "src/main/java/com/google/devtools/coverageoutputgenerator/SonarQubeCoverageReportPrinter.java",
    ],
    main_class = "com.google.devtools.coverageoutputgenerator.SonarQubeCoverageGenerator",
    deps = [
        "@bazel_tools//tools/test/CoverageOutputGenerator/java/com/google/devtools/coverageoutputgenerator:all_lcov_merger_lib",
    ],
)

genrule(
    name = "sonarqube_coverage_generator",
    outs = ["coverage.launcher"],
    cmd = "ln -snf $$(readlink $(location :SonarQubeCoverageGenerator)) $@",
    executable = 1,
    tools = [":SonarQubeCoverageGenerator"],
    visibility = ["//visibility:public"],
)
