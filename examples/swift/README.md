# SwiftUI iOS App with Bazel

This is an iOS application written in SwiftUI and built via Bazel. This is a starting place similar to creating a new project in Xcode and choosing SwiftUI as the starting place. This example demonstrates how to generate test coverage report on iOs with SonarQube.

## Getting Started

Install Bazelisk via `brew install bazelisk`. `bazel` & `bazelisk` will now use the `.bazelversion` file to download and run the chosen Bazel version.

### Generate/Open Project

```bash
$ bazel run :xcodeproj
$ open App.xcodeproj
```

### Build Application (CLI)

```bash
$ bazel build //app
```

### Tests and test coverage with SonarQube

To generate test coverage first run `bazel coverage`

```bash
$ bazel coverage //modules/API:APITests
```

After that's done, run `sonar-scanner` CLI

```bash
$ bazel run //:sq -- -Dsonar.host.url=https://sonarqube.company-name.com -Dsonar.login=SONAR_API_TOKEN
```

#### Notes regarding test coverage and SonarQube for iOS

* Take a look at `.bazelrc` file, pay attention to coverage related flags.
* See `--instruentation_filter` flag also in `.bazelrc`.
* Even though you can set some basic properties on `sonarqube`Bazel rule itself, additional properties like exclusions or other language-specific stuff  should be done manually in `sonar-project.properties.tpl`.
* Ensure that test coverage generation and Sonar scanner run on the same machine on CI.

## Underlying Tools

- [`rules_apple`](https://github.com/bazelbuild/rules_apple)
- [`rules_swift`](https://github.com/bazelbuild/rules_swift)
- [`rules_xcodeproj`](https://github.com/MobileNativeFoundation/rules_xcodeproj)
- [`bazel_sonarqube`](https://github.com/zetten/bazel-sonarqube)

## Making It Your Own

`tools/shared.bzl` contains a handful of definitions to define the name of the application, bundle identifier, and similar things. Update these values to change the application's name.
