<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#sonarqube"></a>

## sonarqube

<pre>
sonarqube(<a href="#sonarqube-name">name</a>, <a href="#sonarqube-project_key">project_key</a>, <a href="#sonarqube-scm_info">scm_info</a>, <a href="#sonarqube-coverage_report">coverage_report</a>, <a href="#sonarqube-project_name">project_name</a>, <a href="#sonarqube-srcs">srcs</a>, <a href="#sonarqube-source_encoding">source_encoding</a>,
          <a href="#sonarqube-targets">targets</a>, <a href="#sonarqube-test_srcs">test_srcs</a>, <a href="#sonarqube-test_targets">test_targets</a>, <a href="#sonarqube-test_reports">test_reports</a>, <a href="#sonarqube-modules">modules</a>, <a href="#sonarqube-sonar_scanner">sonar_scanner</a>,
          <a href="#sonarqube-sq_properties_template">sq_properties_template</a>, <a href="#sonarqube-tags">tags</a>, <a href="#sonarqube-visibility">visibility</a>)
</pre>

A runnable rule to execute SonarQube analysis.

Generates `sonar-project.properties` and invokes the SonarScanner CLI tool
to perform the analysis.


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| name |  Name of the target.   |  none |
| project_key |  SonarQube project key, e.g. <code>com.example.project:module</code>.   |  none |
| scm_info |  Source code metadata. For example, to include Git data from     the workspace root, create a filegroup:<br><br>    <code>filegroup(name = "git_info", srcs = glob([".git/**"], exclude = [".git/**/*[*"]))</code><br><br>    and reference it as <code>scm_info = [":git_info"],</code>.   |  none |
| coverage_report |  Coverage file in SonarQube generic coverage report     format. This can be created using the generator from this project     (see the README for example usage).   |  <code>None</code> |
| project_name |  SonarQube project display name.   |  <code>None</code> |
| srcs |  Project sources to be analysed by SonarQube.   |  <code>[]</code> |
| source_encoding |  Source file encoding.   |  <code>None</code> |
| targets |  Bazel targets to be analysed by SonarQube.<br><br>    These may be used to provide additional provider information to the     SQ analysis , e.g. Java classpath context.   |  <code>[]</code> |
| test_srcs |  Project test sources to be analysed by SonarQube. This must     be set along with <code>test_reports</code> and <code>test_sources</code> for accurate     test reporting.   |  <code>[]</code> |
| test_targets |  A list of test targets relevant to the SQ project. This     will be used with the <code>test_reports</code> attribute to generate the     report paths in sonar-project.properties.   |  <code>[]</code> |
| test_reports |  Targets describing Junit-format execution reports. May be     configured in the workspace root to use Bazel's execution reports     as below:<br><br>    <code>filegroup(name = "test_reports", srcs = glob(["bazel-testlogs/**/test.xml"]))</code><br><br>    and referenced as <code>test_reports = [":test_reports"],</code>.<br><br>    **Note:** this requires manually executing <code>bazel test</code> or <code>bazel     coverage</code> before running the <code>sonarqube</code> target.   |  <code>[]</code> |
| modules |  Sub-projects to associate with this SonarQube project, i.e.     <code>sq_project</code> targets.   |  <code>{}</code> |
| sonar_scanner |  Bazel binary target to execute the SonarQube CLI Scanner.   |  <code>"@bazel_sonarqube//:sonar_scanner"</code> |
| sq_properties_template |  Template file for <code>sonar-project.properties</code>.   |  <code>"@bazel_sonarqube//:sonar-project.properties.tpl"</code> |
| tags |  Bazel target tags, e.g. <code>["manual"]</code>.   |  <code>[]</code> |
| visibility |  Bazel target visibility, e.g. <code>["//visibility:public"]</code>.   |  <code>[]</code> |


<a name="#sq_project"></a>

## sq_project

<pre>
sq_project(<a href="#sq_project-name">name</a>, <a href="#sq_project-project_key">project_key</a>, <a href="#sq_project-project_name">project_name</a>, <a href="#sq_project-srcs">srcs</a>, <a href="#sq_project-source_encoding">source_encoding</a>, <a href="#sq_project-targets">targets</a>, <a href="#sq_project-test_srcs">test_srcs</a>, <a href="#sq_project-test_targets">test_targets</a>,
           <a href="#sq_project-test_reports">test_reports</a>, <a href="#sq_project-modules">modules</a>, <a href="#sq_project-sq_properties_template">sq_properties_template</a>, <a href="#sq_project-tags">tags</a>, <a href="#sq_project-visibility">visibility</a>)
</pre>

A configuration rule to generate SonarQube analysis properties.

Targets of this type may be referenced by the [`modules`](#sonarqube-modules)
attribute of the `sonarqube` rule, to create a multi-module SonarQube
project.


**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| name |  Name of the target.   |  none |
| project_key |  SonarQube project key, e.g. <code>com.example.project:module</code>.   |  none |
| project_name |  SonarQube project display name.   |  <code>None</code> |
| srcs |  Project sources to be analysed by SonarQube.   |  <code>[]</code> |
| source_encoding |  Source file encoding.   |  <code>None</code> |
| targets |  Bazel targets to be analysed by SonarQube.<br><br>    These may be used to provide additional provider information to the     SQ analysis , e.g. Java classpath context.   |  <code>[]</code> |
| test_srcs |  Project test sources to be analysed by SonarQube. This must     be set along with <code>test_reports</code> and <code>test_sources</code> for accurate     test reporting.   |  <code>[]</code> |
| test_targets |  A list of test targets relevant to the SQ project. This     will be used with the <code>test_reports</code> attribute to generate the     report paths in sonar-project.properties.   |  <code>[]</code> |
| test_reports |  Targets describing Junit-format execution reports. May be     configured in the workspace root to use Bazel's execution reports     as below:<br><br>    <code>filegroup(name = "test_reports", srcs = glob(["bazel-testlogs/**/test.xml"]))</code><br><br>    and referenced as <code>test_reports = [":test_reports"],</code>.<br><br>    **Note:** this requires manually executing <code>bazel test</code> or <code>bazel     coverage</code> before running the <code>sonarqube</code> target.   |  <code>[]</code> |
| modules |  Sub-projects to associate with this SonarQube project, i.e.     <code>sq_project</code> targets.   |  <code>{}</code> |
| sq_properties_template |  Template file for <code>sonar-project.properties</code>.   |  <code>"@bazel_sonarqube//:sonar-project.properties.tpl"</code> |
| tags |  Bazel target tags, e.g. <code>["manual"]</code>.   |  <code>[]</code> |
| visibility |  Bazel target visibility, e.g. <code>["//visibility:public"]</code>.   |  <code>[]</code> |


