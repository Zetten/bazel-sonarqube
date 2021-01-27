workspace(name = "bazel_sonarqube")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//:repositories.bzl", "bazel_sonarqube_repositories")

bazel_sonarqube_repositories()

http_archive(
    name = "io_bazel_stardoc",
    sha256 = "6d07d18c15abb0f6d393adbd6075cd661a2219faab56a9517741f0fc755f6f3c",
    strip_prefix = "stardoc-0.4.0",
    urls = ["https://github.com/bazelbuild/stardoc/archive/0.4.0.tar.gz"],
)

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")

stardoc_repositories()
