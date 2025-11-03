load("@bazel_sonarqube//:defs.bzl", "sq_project")

sq_project(
    name = "sq_subproject",
    srcs = ["//subproject/src/main/java/com/example:java_srcs"],
    project_key = "com.example.project:subproject",
    project_name = "My Project :: Sub-Project",
    tags = ["manual"],
    targets = ["//subproject/src/main/java/com/example:app"],
    test_reports = ["//:test_reports"],
    test_srcs = ["//subproject/src/test/java/com/example:java_test_srcs"],
    test_targets = [
        # can use test_suite to reference multiple tests
        "//subproject/src/test/java/com/example:mySuite",

        # or individually like before
        "//subproject/src/test/java/com/example:AppTest3",
    ],
    visibility = ["//visibility:public"],
    testonly = True,
)
