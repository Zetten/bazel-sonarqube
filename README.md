# Bazel-SonarQube integration

Utilities to help analyse Bazel projects with SonarQube.

## Coverage

To aggregate and convert Bazel coverage into SQ's generic coverage XML format:

```sh
bazel test <targets> --collect_code_coverage \
  --combined_report=lcov \
  --coverage_report_generator=@bazel_sonarqube//:sonarqube_coverage_generator
```

The output file (`bazel-out/_coverage/_coverage_report.dat`) may be given as
the value to the analysis property `sonar.coverageReportPaths`.

