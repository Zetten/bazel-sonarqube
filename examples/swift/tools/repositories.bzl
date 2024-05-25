load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_dependency():
    http_archive(
        name = "SwiftLint",
        build_file_content = """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
native_binary(
    name = "swiftlint",
    src = "bin/swiftlint",
    out = "swiftlint",
    visibility = ["//visibility:public"],
)
""",
        sha256 = "03416a4f75f023e10f9a76945806ddfe70ca06129b895455cc773c5c7d86b73e",
        strip_prefix = "SwiftLintBinary.artifactbundle/swiftlint-0.53.0-macos",
        url = "https://github.com/realm/SwiftLint/releases/download/0.53.0/SwiftLintBinary-macos.artifactbundle.zip",
    )
