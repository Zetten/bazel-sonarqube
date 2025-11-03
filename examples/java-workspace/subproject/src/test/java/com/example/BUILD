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
    srcs = ["AppTest.java"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
    size = "small",
)

java_test(
    name = "AppTest2",
    srcs = ["AppTest2.java"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
    size = "small",
)

java_test(
    name = "AppTest3",
    srcs = ["AppTest3.java"],
    deps = [
        "//subproject/src/main/java/com/example:app",
        "@maven//:junit_junit",
    ],
    size = "small",
    visibility = ["//visibility:public"],
)
