load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def bazel_sonarqube_repositories(
        sonar_scanner_cli_version = "4.2.0.1873",
        sonar_scanner_cli_sha256 = "c1903a3f4cb8ad4f0eeaf8e478b667fbe9eb6ec595db558486761404b88d0b2d"):
    http_archive(
        name = "org_sonarsource_scanner_cli_sonar_scanner_cli",
        build_file = "@bazel_sonarqube//:BUILD.sonar_scanner",
        sha256 = sonar_scanner_cli_sha256,
        strip_prefix = "sonar-scanner-" + sonar_scanner_cli_version,
        urls = [
            "https://repo1.maven.org/maven2/org/sonarsource/scanner/cli/sonar-scanner-cli/%s/sonar-scanner-cli-%s.zip" % (sonar_scanner_cli_version, sonar_scanner_cli_version),
            "https://jcenter.bintray.com/org/sonarsource/scanner/cli/sonar-scanner-cli/%s/sonar-scanner-cli-%s.zip" % (sonar_scanner_cli_version, sonar_scanner_cli_version),
        ],
    )
