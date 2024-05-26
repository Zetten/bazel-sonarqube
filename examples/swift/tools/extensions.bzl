load("//tools:repositories.bzl", "swiftlint_dependency")

def _non_module_dependencies_impl(_ctx):
    swiftlint_dependency()

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
