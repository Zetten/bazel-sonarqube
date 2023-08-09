filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = [ "//visibility:public" ],
)

java_test(
    name = "SeparateSubSubAppTest",
    srcs = [ "SeparateSubSubAppTest.java" ],
    deps = [
        "//subproject-with-separate-sonarqube/subsubproject/src/main/java/com/separate/subsubproject",
        "@maven//:junit_junit",
    ],
    size = "small",
    visibility = [ "//visibility:public" ],
)
