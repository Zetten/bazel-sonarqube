# Examples

These sample projects demonstrate some usage of Bazel with the bazel_sonarqube
rules.

A typical analysis workflow in these examples will follow the steps:

1. `bazel coverage //...`
2. `bazel run //:sonarqube`

Note that the analysis requires a connection to a SonarQube server.

If an external server is available, pass the arguments to the SonarScanner:

```
bazel run //:sonarqube -- -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_AUTH_TOKEN}
```

Alternatively,
see https://docs.sonarqube.org/latest/setup/get-started-2-minutes/.
