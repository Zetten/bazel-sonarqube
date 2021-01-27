filegroup(
    name = "java_test_srcs",
    srcs = glob(["*.java"]),
    visibility = ["//visibility:public"],
)

java_test(
    name = "AppTest",
    srcs = [":java_test_srcs"],
    visibility = ["//visibility:public"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
)
