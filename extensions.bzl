load("//:repositories.bzl", "bazel_sonarqube_repositories")

def _non_module_dependencies_impl(_ctx):
    bazel_sonarqube_repositories()

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
