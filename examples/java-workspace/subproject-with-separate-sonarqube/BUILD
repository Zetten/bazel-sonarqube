load("@bazel_sonarqube//:defs.bzl", "sonarqube")

sonarqube(
    name = "sonarqube",
    srcs = [
        "//subproject-with-separate-sonarqube/src/main/java/com/separate:srcs",
    ],
    targets = [
        "//subproject-with-separate-sonarqube/src/main/java/com/separate",
    ],
    test_reports = [ "//:test_reports" ],
    test_srcs = [ 
        "//subproject-with-separate-sonarqube/src/test/java/com/separate:srcs", 
    ],
    test_targets = [ 
        "//subproject-with-separate-sonarqube/src/test/java/com/separate:SeparateAppTest", 
    ],
    modules = {
        "//subproject-with-separate-sonarqube/subsubproject:sq_project": "subproject-with-separate-sonarqube/subsubproject",
    },
    coverage_report = "//:coverage_report",
    project_key = "com.example.separate:separate",
    project_name = "My Project with Separate sonarqube rule",
    scm_info = ["//:git"],
    tags = ["manual"],
    testonly = True,
)
