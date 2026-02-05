load("@rules_java//java:java_test.bzl", "java_test")

filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = ["//visibility:public"],
)

java_test(
    name = "SeparateSubSubAppTest",
    size = "small",
    srcs = ["SeparateSubSubAppTest.java"],
    visibility = ["//visibility:public"],
    deps = [
        "//subproject-with-separate-sonarqube/subsubproject/src/main/java/com/separate/subsubproject",
        "@maven//:junit_junit",
    ],
)
