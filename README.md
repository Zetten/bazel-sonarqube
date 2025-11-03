# Bazel-SonarQube integration

Utilities to help analyse Bazel projects with SonarQube.

[Generated stardoc rule documentation](./docs/bazel_sonarqube.md)

[Example projects](./examples)

## Version compatibility

The SonarQubeCoverageGenerator utility is a direct copy of the equivalent lcov
generator from Bazel upstream, and runs with Bazel's embedded
`"@remote_coverage_tools//:all_lcov_merger_lib"` as a dependency. If using this
to collect coverage info in SQ-compatible format, the version of this repository
must be matched to the Bazel version being used.

The list below includes the last compatible commit of this repository for
specific Bazel versions, otherwise the latest should work with the latest Bazel.

* Bazel < 6.0 - 37261de24f80b661bbc4726e3382ef43e9d66a6e

## Setup

### With bzlmod (Bazel 7 and above)

If you are starting a new project, or your project is already using Bazel 7 and
above, we recommend using [`bzlmod`](https://bazel.build/external/overview).

Add the following to your `MODULE.bazel` file, setting the `version` to the latest one
available on [Bazel Central Registry](https://registry.bazel.build/modules/bazel_sonarqube):

```python
bazel_dep(name = "bazel_sonarqube", version = "...", dev_dependency = True)
```

#### Change version of the sonar_scanner_cli

All possible `sonar_scanner_cli` versions could be found [on github page](https://github.com/SonarSource/sonar-scanner-cli/releases).
Together with version you must provide [SHA-256](https://en.wikipedia.org/wiki/SHA-2).
The easiest way to get `SHA-256` is run command `bazel aquery ...`.
It will display error with desired and current hash.

Example of usage:

```python
bazel_dep(name = "bazel_sonarqube", version = "...", dev_dependency = True)
non_module_dependencies = use_extension("@bazel_sonarqube//:extensions.bzl", "non_module_dependencies")
non_module_dependencies.settings(
    sonar_scanner_cli_version = "6.0.0.4432",
    sonar_scanner_cli_sha256 = "965a18c438a213aa2167b51c793116987bc2a9df9ad245c8e02d3ab3e54022e7",
)
use_repo(non_module_dependencies, "org_sonarsource_scanner_cli_sonar_scanner_cli")
```

### With WORKSPACE file (legacy)

The included rules require some dependencies. In your `WORKSPACE`:

```python
load("@bazel_sonarqube//:repositories.bzl", "bazel_sonarqube_repositories")

bazel_sonarqube_repositories()
```

## Coverage

To aggregate and convert Bazel coverage into SQ's generic coverage XML format:

```sh
bazel test <targets> --collect_code_coverage \
  --combined_report=lcov \
  --coverage_report_generator=@bazel_sonarqube//:sonarqube_coverage_generator
```

The output file (`bazel-out/_coverage/_coverage_report.dat`) may be given as
the value to the analysis property `sonar.coverageReportPaths`, or added as a
Bazel target to use in the analysis rules.

## Test reports

Bazel already emits test reports in the required JUnit XML format, however the
filenames expected by SonarQube differ slightly. These rules will copy the
reports for any configured test targets into supported filenames.

See below for an example. Note that all three `sq_project` attributes must be
set for successful test reporting: `test_srcs`, `test_reports`, `test_targets`.

## Executing analysis

To execute a SonarQube analysis of a Bazel project, two rules are provided:
`sonarqube` and `sq_project`.

The `sonarqube` rule creates an executable target which will generate SonarQube
`sonar-project.properties` configuration files, and execute the CLI scanner.

The `sq_project` rule provides the generation of `sonar-project.properties`
configuration, and can be used to create sub-module configurations to be
included in a `sonarqube` target.

The `sonarqube` rule can then be instantiated:

```python
filegroup(
    name = "git",
    srcs = glob(
        [".git/**"],
        exclude = [".git/**/*[*"],  # gitk creates temp files with []
    ),
    tags = ["manual"],
)

filegroup(
    name = "coverage_report",
    srcs = ["bazel-out/_coverage/_coverage_report.dat"], # Created manually
    tags = ["manual"],
)

filegroup(
    name = "test_reports",
    srcs = glob(["bazel-testlogs/**/test.xml"]), # Created manually
    tags = ["manual"],
)

load("@bazel_sonarqube//:defs.bzl", "sonarqube")

sonarqube(
    name = "sq",
    project_key = "com.example.project:project",
    project_name = "My Project",
    srcs = [
        "//path/to/package:java_srcs",
        "//path/to/another/package:py_srcs",
        "//path/to/yet/another/package:js_srcs",
    ],
    targets = [
        "//path/to/package:package",
    ],
    modules = {
        "//path/to/component:sq_mycomponent": "path/to/component",
    },
    coverage_report = ":coverage_report",
    scm_info = [":git"],
    tags = ["manual"],
    testonly = True,
)
```

The `name` attribute is target name. It is optional attribute, needed when
multiple `sonarqube` is used in the same `BUILD` package.
If not specifie `sonarscan` target name is used.

The `srcs` and `test_srcs` attributes may refer to individual files or
`filegroup` targets.

The `targets` attribute allows Bazel to utilise JavaInfo (from appropriate
targets) to add project and dependency jars to the analysis classpath.

The `modules` attribute should reference (with relative paths) any `sq_project`
targets which should be added as project modules in SonarQube.

The `sq_project` rule instantiation is very similar, here including the
required attributes for test reporting (note that we share a single `filegroup`
in the root `BUILD` file to export all test reports, but it is filtered by
`sq_project` for only those reports matching `test_targets`):

```python
load("@bazel_sonarqube//:defs.bzl", "sq_project")

sq_project(
    name = "sq_mycomponent",
    project_key = "com.example.project:component",
    project_name = "My Project :: Component",
    srcs = [
        "//path/to/component:java_srcs",
    ],
    targets = [
        "//path/to/component:component",
    ],
    test_srcs = ["//path/to/component:java_test_srcs"],
    test_targets = [
        "//path/to/component:FirstComponentTest",
        "//path/to/component:SecondComponentTest",
        "//path/to/component:TestSuite",
    ],
    test_reports = ["//:test_reports"],
    tags = ["manual"],
    visibility = ["//visibility:public"],
    testonly = True,
)
```

Analysis can then be executed:

```sh
bazel run //:sq -- -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_AUTH_TOKEN}
```

Note that during analysis, the `sonarqube` executable target will dereference
its runfiles symlinks. This is necessary so the SCM info correctly resolves,
allowing SonarQube to track new code and line ownership data.
