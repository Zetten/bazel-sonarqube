load("//:repositories.bzl", "bazel_sonarqube_repositories")

def root_module_tags(module_ctx, tag_class_names):
    """Returns the `bazel_module_tags` from the root `bazel_module`.

    If the root module doesn't use the module extension (`module_ctx` doesn't
    contain the root module), returns a `struct` constructed from
    `tag_class_names`. This is useful for configuring default values in that
    case, without having to add extra module extension logic.

    Args:
        module_ctx: the module extension context
        tag_class_names: tag classes used to create a struct if no root module
            detected

    Returns:
        `bazel_module_tags` or a `struct` constructed from `tag_class_names`
    """
    for module in module_ctx.modules:
        if module.is_root:
            return module.tags
    return struct(**{name: [] for name in tag_class_names})

_single_tag_err = (
    "expected one regular tag instance and/or one dev_dependency instance, " +
    "got %s:"
)

def single_tag_values(module_ctx, tags, tag_defaults):
    """Returns a dictionary of tag `attr` names to explicit or default values.

    Use for tags that should appear at most once in a module as a regular tag
    and at most once as a `dev_dependency` tag.

    Nondefault values from a `dev_dependency` instance will override the regular
    instance's values.

    Fails if `tags` contains more than two tag instances, if both are
    `dev_dependency` or regular instances, or if the regular instance doesn't
    come first.

    Args:
        module_ctx: the module extension context
        tags: a list of tag class values from a `bazel_module_tags` object
        tag_defaults: a dictionary of tag attr names to default values

    Returns:
        a dict of tag `attr` names to values
    """
    if len(tags) == 0:
        return tag_defaults
    if len(tags) > 2:
        fail(_single_tag_err % len(tags), *tags)

    result = {k: getattr(tags[0], k) for k in tag_defaults}

    if len(tags) == 2:
        first_is_dev = module_ctx.is_dev_dependency(tags[0])
        second_is_dev = module_ctx.is_dev_dependency(tags[1])

        if first_is_dev == second_is_dev:
            tag_type = "dev_dependency" if first_is_dev else "regular"
            fail(_single_tag_err % ("two %s instances" % (tag_type)), *tags)

        elif first_is_dev:
            msg = "the dev_dependency instance before the regular instance"
            fail(_single_tag_err % msg, *tags)

        dev_dep_values = {k: getattr(tags[1], k) for k in tag_defaults}
        result.update({
            k: v
            for k, v in dev_dep_values.items()
            if v != tag_defaults[k]
        })

    return result

_settings_defaults = {
    "sonar_scanner_cli_version": "5.0.2.4997",
    "sonar_scanner_cli_sha256": "2f10fe6ac36213958201a67383c712a587e3843e32ae1edf06f01062d6fd1407",
}

_settings_attrs = {
    "sonar_scanner_cli_version": attr.string(
        default = _settings_defaults["sonar_scanner_cli_version"],
        doc = (
            "Requested `sonar-scanner-cli` version."
        ),
    ),
    "sonar_scanner_cli_sha256": attr.string(
        default = _settings_defaults["sonar_scanner_cli_sha256"],
        doc = (
            "The expected SHA-256 of `sonar-scanner-cli` file."
        ),
    ),
}

def _non_module_dependencies_impl(module_ctx):
    tags = root_module_tags(module_ctx, ['settings'])
    settings = single_tag_values(module_ctx, tags.settings, _settings_defaults)
    bazel_sonarqube_repositories(
        sonar_scanner_cli_version = settings["sonar_scanner_cli_version"],
        sonar_scanner_cli_sha256 = settings["sonar_scanner_cli_sha256"],
    )

non_module_dependencies = module_extension(
    doc = (
        "Configures `bazel_sonarqube` common parameters"
    ),
    implementation = _non_module_dependencies_impl,
    tag_classes = {
        "settings": tag_class(
            attrs = _settings_attrs,
            doc = "Allows customization of global `bazel_sonarqube` parameters",
        ),
    }
)
