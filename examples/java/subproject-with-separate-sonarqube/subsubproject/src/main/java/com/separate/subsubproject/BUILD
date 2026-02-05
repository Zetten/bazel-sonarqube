load("@rules_java//java:java_library.bzl", "java_library")

filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = ["//visibility:public"],
)

java_library(
    name = "subsubproject",
    srcs = [":srcs"],
    visibility = ["//visibility:public"],
)
