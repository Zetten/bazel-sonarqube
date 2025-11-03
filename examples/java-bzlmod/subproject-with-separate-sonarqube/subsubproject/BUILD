load("@bazel_sonarqube//:defs.bzl", "sq_project")

sq_project(
    name = "sq_project",
    srcs = [
        "//subproject-with-separate-sonarqube/subsubproject/src/main/java/com/separate/subsubproject:srcs", 
    ],
    project_key = "com.example.separate:subsubproject",
    project_name = "My Project :: Sub-Project's sub project for separate sonarqube",
    tags = ["manual"],
    targets = [
        "//subproject-with-separate-sonarqube/subsubproject/src/main/java/com/separate/subsubproject",
    ],
    test_reports = ["//:test_reports"],
    test_srcs = [
        "//subproject-with-separate-sonarqube/subsubproject/src/test/java/com/separate/subsubproject:srcs",
    ],
    test_targets = [
        "//subproject-with-separate-sonarqube/subsubproject/src/test/java/com/separate/subsubproject:SeparateSubSubAppTest",
    ],
    visibility = ["//visibility:public"],
    testonly = True,
)
