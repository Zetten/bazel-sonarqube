load("@bazel_version//:bazel_version.bzl", "bazel_version")
load("@bazel_skylib//lib:versions.bzl", "versions")

def sonarqube_coverage_generator_binary():
    if versions.is_at_least(threshold = "2.1.0", version = bazel_version):
        deps = ["@remote_coverage_tools//:all_lcov_merger_lib"]
    else:
        deps = ["@bazel_tools//tools/test/CoverageOutputGenerator/java/com/google/devtools/coverageoutputgenerator:all_lcov_merger_lib"]

    native.java_binary(
        name = "SonarQubeCoverageGenerator",
        srcs = [
            "src/main/java/com/google/devtools/coverageoutputgenerator/SonarQubeCoverageGenerator.java",
            "src/main/java/com/google/devtools/coverageoutputgenerator/SonarQubeCoverageReportPrinter.java",
        ],
        main_class = "com.google.devtools.coverageoutputgenerator.SonarQubeCoverageGenerator",
        deps = deps,
    )

def _build_sonar_project_properties(ctx, sq_properties_file):
    module_path = ctx.build_file_path.replace("BUILD", "")
    depth = len(module_path.split("/")) - 1
    parent_path = "../" * depth
    if hasattr(ctx.attr, "coverage_report") and ctx.attr.coverage_report:
        coverage_report_path = parent_path + ctx.file.coverage_report.short_path
        coverage_runfiles = [ctx.file.coverage_report]
    else:
        coverage_report_path = ""
        coverage_runfiles = []

    java_files = _get_java_files([t for t in ctx.attr.targets if t[JavaInfo]])

    ctx.actions.expand_template(
        template = ctx.file.sq_properties_template,
        output = sq_properties_file,
        substitutions = {
            "{PROJECT_KEY}": ctx.attr.project_key,
            "{PROJECT_NAME}": ctx.attr.project_name,
            "{SOURCES}": ",".join([parent_path + f.short_path for f in ctx.files.srcs]),
            "{SOURCE_ENCODING}": ctx.attr.source_encoding,
            "{JAVA_BINARIES}": ",".join([parent_path + j.short_path for j in java_files["output_jars"].to_list()]),
            "{JAVA_LIBRARIES}": ",".join([parent_path + j.short_path for j in java_files["deps_jars"].to_list()]),
            "{MODULES}": ",".join(ctx.attr.modules.values()),
            "{TESTS}": ",".join([parent_path + f.short_path for f in ctx.files.tests]),
            "{TEST_EXECUTION_REPORT_PATHS}": ",".join([parent_path + f.short_path for f in ctx.files.test_execution_report_paths]),
            "{COVERAGE_REPORT}": coverage_report_path,
            "{JAVASCRIPT_LCOV_REPORT_PATHS}": ",".join([parent_path + f.short_path for f in ctx.files.javascript_lcov_report_paths]),
            "{JAVASCRIPT_ESLINT_REPORT_PATHS}": ",".join([parent_path + f.short_path for f in ctx.files.javascript_eslint_report_paths]),
            "{TYPESCRIPT_LCOV_REPORT_PATHS}": ",".join([parent_path + f.short_path for f in ctx.files.typescript_lcov_report_paths]),
            "{TYPESCRIPT_TSLINT_REPORT_PATHS}": ",".join([parent_path + f.short_path for f in ctx.files.typescript_tslint_report_paths]),
            "{PHP_COVERAGE_REPORT_PATHS}": ",".join([parent_path + f.short_path for f in ctx.files.php_coverage_report_paths]),
            "{PHP_TESTS_REPORT_PATH}": ",".join([parent_path + f.short_path for f in ctx.files.php_tests_report_path]),
        },
        is_executable = False,
    )

    return ctx.runfiles(
        files = [sq_properties_file] + ctx.files.srcs + coverage_runfiles,
        transitive_files = depset(transitive = [java_files["output_jars"], java_files["deps_jars"]]),
    )

def _get_java_files(java_targets):
    return {
        "output_jars": depset(direct = [j.class_jar for t in java_targets for j in t[JavaInfo].outputs.jars]),
        "deps_jars": depset(transitive = [t[JavaInfo].transitive_deps for t in java_targets] + [t[JavaInfo].transitive_runtime_deps for t in java_targets]),
    }

def _sonarqube_impl(ctx):
    sq_properties_file = ctx.actions.declare_file("sonar-project.properties")

    local_runfiles = _build_sonar_project_properties(ctx, sq_properties_file)

    module_runfiles = ctx.runfiles(files = [])
    for module in ctx.attr.modules.keys():
        module_runfiles = module_runfiles.merge(module[DefaultInfo].default_runfiles)

    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join([
            "#!/bin/bash",
            "echo 'Dereferencing bazel runfiles symlinks for accurate SCM resolution...'",
            "for f in $(find $(dirname %s) -type l); do sed -i '' $f; done" % sq_properties_file.short_path,
            "echo '... done.'",
            "exec %s -Dproject.settings=%s $@" % (ctx.executable.sonar_scanner.short_path, sq_properties_file.short_path),
        ]),
        is_executable = True,
    )

    return [DefaultInfo(
        runfiles = ctx.runfiles(files = [ctx.executable.sonar_scanner] + ctx.files.scm_info).merge(ctx.attr.sonar_scanner[DefaultInfo].default_runfiles).merge(local_runfiles).merge(module_runfiles),
    )]

_COMMON_ATTRS = dict(dict(), **{
    "project_key": attr.string(
        mandatory = True,
        doc = """SonarQube project key, e.g. `com.example.project:module`.""",
    ),
    "project_name": attr.string(
        doc = """SonarQube project display name.""",
    ),
    "srcs": attr.label_list(
        allow_files = True,
        default = [],
        doc = """Project sources to be analysed by SonarQube.""",
    ),
    "source_encoding": attr.string(
        default = "UTF-8",
        doc = """Source file encoding.""",
    ),
    "targets": attr.label_list(
        default = [],
        doc = """Bazel targets to be analysed by SonarQube.

            These may be used to provide additional provider information to the SQ analysis , e.g. Java classpath context.
            """,
    ),
    "modules": attr.label_keyed_string_dict(
        default = {},
        doc = """Sub-projects to associate with this SonarQube project.""",
    ),
    "tests": attr.label_list(
        allow_files = True,
        default = [],
        doc = """Test source files""",
    ),
    "test_execution_report_paths": attr.label_list(
        allow_files = True,
        default = [],
        doc = """Execution reports in the Generic Execution Data format""",
    ),
    "javascript_lcov_report_paths": attr.label_list(
        allow_files = True,
        default = [],
        doc = """JavaScript LCOV coverage report files""",
    ),
    "javascript_eslint_report_paths": attr.label_list(
        allow_files = True,
        default = [],
        doc = """ESLint reports in JSON format""",
    ),
    "typescript_lcov_report_paths": attr.label_list(
        allow_files = True,
        default = [],
        doc = """TypeScript LCOV coverage report files""",
    ),
    "typescript_tslint_report_paths": attr.label_list(
        allow_files = True,
        default = [],
        doc = """TSLint reports in JSON format""",
    ),
    "php_coverage_report_paths": attr.label_list(
        allow_files = True,
        default = [],
        doc = """Clover XML-format coverage report files""",
    ),
    "php_tests_report_path": attr.label(
        allow_single_file = True,
        default = "",
        doc = """PHPUnit unit test execution report file""",
    ),
    "sq_properties_template": attr.label(
        allow_single_file = True,
        default = "@bazel_sonarqube//:sonar-project.properties.tpl",
        doc = """Template file for sonar-project.properties.""",
    ),
    "sq_properties": attr.output(),
})

_sonarqube = rule(
    attrs = dict(_COMMON_ATTRS, **{
        "coverage_report": attr.label(
            allow_single_file = True,
            mandatory = False,
            doc = """Coverage file in SonarQube generic coverage report format.""",
        ),
        "scm_info": attr.label_list(
            allow_files = True,
            doc = """Source code metadata, e.g. `filegroup(name = "git_info", srcs = glob([".git/**"], exclude = [".git/**/*[*"],  # gitk creates temp files with []))`""",
        ),
        "sonar_scanner": attr.label(
            executable = True,
            default = "@bazel_sonarqube//:sonar_scanner",
            cfg = "host",
            doc = """Bazel binary target to execute the SonarQube CLI Scanner""",
        ),
    }),
    fragments = ["jvm"],
    host_fragments = ["jvm"],
    implementation = _sonarqube_impl,
    executable = True,
)

def sonarqube(
        name,
        project_key,
        scm_info,
        coverage_report = None,
        project_name = None,
        srcs = [],
        source_encoding = None,
        targets = [],
        modules = {},
        sonar_scanner = None,
        sq_properties_template = None,
        tags = [],
        visibility = []):
    _sonarqube(
        name = name,
        project_key = project_key,
        project_name = project_name,
        scm_info = scm_info,
        coverage_report = coverage_report,
        srcs = srcs,
        source_encoding = source_encoding,
        targets = targets,
        modules = modules,
        sonar_scanner = sonar_scanner,
        sq_properties_template = sq_properties_template,
        sq_properties = "sonar-project.properties",
        tags = tags,
        visibility = visibility,
    )

def _sq_project_impl(ctx):
    local_runfiles = _build_sonar_project_properties(ctx, ctx.outputs.sq_properties)

    return [DefaultInfo(
        runfiles = local_runfiles,
    )]

_sq_project = rule(
    attrs = _COMMON_ATTRS,
    implementation = _sq_project_impl,
)

def sq_project(
        name,
        project_key,
        project_name = None,
        srcs = [],
        source_encoding = None,
        targets = [],
        modules = {},
        tests = [],
        test_execution_report_paths = [],
        coverage_report = None,
        javascript_lcov_report_paths = [],
        javascript_eslint_report_paths = [],
        typescript_lcov_report_paths = [],
        typescript_tslint_report_paths = [],
        php_coverage_report_paths = [],
        php_tests_report_path = None,
        sq_properties_template = None,
        tags = [],
        visibility = []):
    _sq_project(
        name = name,
        project_key = project_key,
        project_name = project_name,
        srcs = srcs,
        source_encoding = source_encoding,
        targets = targets,
        modules = modules,
        tests = tests,
        test_execution_report_paths = test_execution_report_paths,
        javascript_lcov_report_paths = javascript_lcov_report_paths,
        typescript_lcov_report_paths = typescript_tslint_report_paths,
        php_coverage_report_paths = php_coverage_report_paths,
        php_tests_report_path = php_tests_report_path,
        sq_properties_template = sq_properties_template,
        sq_properties = "sonar-project.properties",
        tags = tags,
        visibility = visibility,
    )
