# Develop nf-core

Nextflow provides a powerful way to develop pipelines. However, it does not provide standards for how pipelines should be developed. This gap has led to the establishment of pipeline registries, such as [nf-core](https://nf-co.re/), with tools and implementation guidelines that provide support and standards for pipeline development.

nf-core developed a base template to enable standardization and the adoption of good coding practices. The template establishes a pipeline file structure, with code, documentation, and continuous integration (CI) tests. The template plugs into the nf-core tooling, offering a full suite of commands that support pipeline usage and development.

Leveraging the nf-core template enables accelerated maintenance and development of pipelines.

Let's get started!

[![Open in Gitpod](https://img.shields.io/badge/Gitpod-%20Open%20in%20Gitpod-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/nextflow-io/training)

## Learning objectives

In this workshop, you will utilize the nf-core tooling to build a small pipeline using the nf-core template.

By the end of this workshop you will be able to:

-   Discuss the benefits of using the nf-core pipeline template
-   Identify the features of nf-core pipeline template that enable best practices
-   Add nf-core modules to a pipeline using the nf-core tooling
-   Add parameters to a pipeline and update the schema using the nf-core tooling

## Audience & prerequisites

Please note that this is **not** a beginner's workshop and familiarity with Nextflow, the command line, and common file formats is assumed.

**Prerequisites**

-   A GitHub account
-   Experience with command line
-   Experience writing pipelines with Nextflow
