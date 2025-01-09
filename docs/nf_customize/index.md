# Configure nf-core

nf-core is a community effort to collaborate on a curated set of analysis pipelines built using Nextflow. It provides a standardized set of best practices, guidelines, and templates for building and sharing bioinformatics pipelines.

nf-core pipelines are designed to be modular, scalable, and portable, allowing researchers to easily adapt and execute them using their data and compute resources. They are designed to work out of the box. However, many researchers will want to customize their execution to deploy them to different infrastructures, activate or deactivate pipeline features, and selectively customize tool parameters. For this, researchers need to understand how these pipelines fit together and how to apply configuration options.

In this workshop, using the [nf-core/demo](https://github.com/nf-core/demo) pipeline as an example, you will learn how customize parameters and configuration files.

Let's get started!

[![Open in Gitpod](https://img.shields.io/badge/Gitpod-%20Open%20in%20Gitpod-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/nextflow-io/training)

## Learning objectives

By the end of this workshop you will be able to:

-   Discuss the ways an nf-core pipeline can be customized
-   Identify the files and code contributing to the default pipeline configuration
-   Utilize nf-core tooling to list, launch, and download pipelines

## Audience & prerequisites

Please note that this is **not** a beginner's workshop and familiarity with Nextflow, the command line, and common file formats is assumed.

**Prerequisites**

-   A GitHub account
-   Experience with command line
-   Experience writing pipelines with Nextflow
