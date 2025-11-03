filegroup(
    name = "srcs",
    srcs = glob(["*.java"]),
    visibility = [ "//visibility:public" ],
)

java_library(
    name = "subsubproject",
    srcs = [":srcs"],
    visibility = [ "//visibility:public" ],
)
