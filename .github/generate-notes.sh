#!/bin/bash

set -euo pipefail

readonly new_version=$1
readonly release_archive="bazel_sonarqube.$new_version.tar.gz"

sha=$(shasum -a 256 "$release_archive" | cut -d " " -f1)

cat <<EOF
## What's Changed

TODO

### MODULE.bazel Snippet

\`\`\`bzl
bazel_dep(name = "bazel_sonarqube", version = "$new_version", repo_name = "bazel_sonarqube")
\`\`\`

### Workspace Snippet

\`\`\`bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_sonarqube",
    sha256 = "$sha",
    url = "https://github.com/Zetten/bazel-sonarqube/releases/download/$new_version/bazel_sonarqube.$new_version.tar.gz",
)

load(
    "@bazel_sonarqube//:repositories.bzl",
    "bazel_sonarqube_repositories"
)

bazel_sonarqube_repositories()
\`\`\`
EOF
