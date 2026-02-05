load("@rules_java//java:java_test.bzl", "java_test")

filegroup(
    name = "java_test_srcs",
    srcs = glob(["*.java"]),
    visibility = ["//visibility:public"],
)

test_suite(
    name = "mySuite",
    tests = [
        ":AppTest",
        ":AppTest2",
    ],
    visibility = ["//visibility:public"],
)

java_test(
    name = "AppTest",
    size = "small",
    srcs = ["AppTest.java"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
)

java_test(
    name = "AppTest2",
    size = "small",
    srcs = ["AppTest2.java"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
)

java_test(
    name = "AppTest3",
    size = "small",
    srcs = ["AppTest3.java"],
    visibility = ["//visibility:public"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
)
