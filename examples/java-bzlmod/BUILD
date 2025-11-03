filegroup(
    name = "git",
    srcs = glob(
        [".git/**"],
        exclude = [".git/**/*[*"],  # gitk creates temp files with []
    ),
    tags = ["manual"],
)

filegroup(
    name = "coverage_report",
    srcs = ["bazel-out/_coverage/_coverage_report.dat"],  # Created manually
    tags = ["manual"],
)

filegroup(
    name = "test_reports",
    srcs = glob(["bazel-testlogs/**/test.xml"]),  # Created manually
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

load("@bazel_sonarqube//:defs.bzl", "sonarqube")

sonarqube(
    name = "sonarqube",
    srcs = [],
    coverage_report = ":coverage_report",
    modules = {
        "//subproject:sq_subproject": "subproject",
    },
    project_key = "com.example.project:project",
    project_name = "My Project",
    scm_info = [":git"],
    tags = ["manual"],
    targets = [],
    testonly = True,
)
