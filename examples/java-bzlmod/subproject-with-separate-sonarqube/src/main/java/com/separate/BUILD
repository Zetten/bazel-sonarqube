filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = [ "//visibility:public" ],
)

java_library(
    name = "separate",
    srcs = [":srcs"],
    visibility = [ "//visibility:public" ],
)
