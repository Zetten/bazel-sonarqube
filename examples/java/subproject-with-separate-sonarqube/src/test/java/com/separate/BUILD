filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = [ "//visibility:public" ],
)

java_test(
    name = "SeparateAppTest",
    srcs = [ "SeparateAppTest.java" ],
    deps = [
        "//subproject-with-separate-sonarqube/src/main/java/com/separate",
        "@maven//:junit_junit",
    ],
    size = "small",
    visibility = [ "//visibility:public" ],
)
