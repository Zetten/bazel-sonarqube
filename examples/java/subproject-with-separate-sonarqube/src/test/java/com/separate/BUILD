load("@rules_java//java:java_test.bzl", "java_test")

filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = ["//visibility:public"],
)

java_test(
    name = "SeparateAppTest",
    size = "small",
    srcs = ["SeparateAppTest.java"],
    visibility = ["//visibility:public"],
    deps = [
        "//subproject-with-separate-sonarqube/src/main/java/com/separate",
        "@maven//:junit_junit",
    ],
)
