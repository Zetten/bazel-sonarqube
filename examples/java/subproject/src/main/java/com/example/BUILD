load("@rules_java//java:java_library.bzl", "java_library")

filegroup(
    name = "java_srcs",
    srcs = glob(["*.java"]),
    visibility = ["//visibility:public"],
)

java_library(
    name = "app",
    srcs = [":java_srcs"],
    visibility = ["//visibility:public"],
)
