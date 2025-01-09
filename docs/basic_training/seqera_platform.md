---
title: Seqera Platform
description: Get started with Seqera Platform
---

# Get started with Seqera Platform

Seqera Platform, previously known as Nextflow Tower, is the centralized command post for data management and workflows. It brings monitoring, logging and observability to distributed workflows and simplifies the deployment of workflows on any cloud, cluster or laptop. In Seqera Platform terminology, a workflow is what we've been working on so far, and pipelines are pre-configured workflows that can be used by all users in a workspace. It is composed of a workflow repository, launch parameters, and a compute environment. We'll stick to these definitions in this section.

Seqera core features include:

-   The launching of pre-configured pipelines with ease.
-   Programmatic integration to meet the needs of an organization.
-   Publishing pipelines to shared workspaces.
-   Management of the infrastructure required to run data analysis at scale.

!!! tip

    [Sign up](https://cloud.seqera.io/) to try Seqera for free or request a [demo](https://seqera.io/demo/) for deployments in your own on-premise or cloud environment.

You can use Seqera Platform via either the **CLI**, through the **online GUI** or through the **API**.

## CLI

You will need to set up your environment to use Seqera Platform. This is a one-time setup.

Create an account and login into Seqera Platform.

**1. Create a new token**

You can access your tokens from the **Settings** drop-down menu:

![Create a token](img/usage_create_token.png)

**2. Name your token**

![Name your token](img/usage_name_token.png)

**3. Save your token safely**

Copy and keep your new token in a safe place.

![Save token](img/usage_token.png)

**4. Export your token**

Once your token has been created, open a terminal and type:

```bash
export TOWER_ACCESS_TOKEN=eyxxxxxxxxxxxxxxxQ1ZTE=
```

Where `eyxxxxxxxxxxxxxxxQ1ZTE=` is the token you have just created.

!!! note

    Check your `nextflow -version`. Bearer tokens require Nextflow version 20.10.0 or later and can be set with the second command shown above. You can change the version if necessary.

To submit a pipeline to a [Workspace](https://docs.seqera.io/platform/24.1/getting-started/workspace-setup) using the Nextflow command-line tool, add the workspace ID to your environment. For example:

```bash
export TOWER_WORKSPACE_ID=000000000000000
```

The workspace ID can be found on the organization’s Workspaces overview page.

**5. Run Nextflow with Seqera Platform**

Run your Nextflow workflows as usual with the addition of the `-with-tower` command:

```bash
nextflow run hello.nf -with-tower
```

You will see and be able to monitor your **Nextflow jobs** in Seqera Platform.

To configure and execute Nextflow jobs in **Cloud environments**, visit the [Compute environments section](https://docs.seqera.io/platform/24.1/compute-envs/overview).

!!! exercise

    Run the RNA-Seq `script7.nf` using the `-with-tower` flag, after correctly completing the token settings outlined above.

    ??? tip

        Go to <https://cloud.seqera.io/>, login, then click the run tab, and select the run that you just submitted. If you can’t find it, double check your token was entered correctly.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to create and add your token and workspace.
    2. How to launch a pipeline with Seqera Platform.

## Online GUI

To run using the GUI, there are three main steps:

1. Create an account and login into Seqera Platform, available free of charge, at [cloud.seqera.io](https://cloud.seqera.io).
2. Create and configure a new [compute environment](https://docs.seqera.io/platform/24.1/compute-envs/overview).
3. Start [launching pipelines](https://docs.seqera.io/platform/24.1/launch/launchpad#launchpad).

### Configuring your compute environment

Seqera Platform uses the concept of **Compute Environments** to define the execution platform where a workflow will run.

It supports the launching of workflows into a growing number of **cloud** and **on-premise** infrastructures.

![Compute environments](img/compute_env_platforms.png)

Each compute environment must be pre-configured to enable Seqera Platform to submit tasks. You can read more on how to set up each environment using the links below.

!!! tip "The following guides describe how to configure each of these compute environments."

    * [AWS Batch](https://docs.seqera.io/platform/24.1/compute-envs/aws-batch)
    * [Azure Batch](https://docs.seqera.io/platform/24.1/compute-envs/azure-batch)
    * [Google Batch](https://docs.seqera.io/platform/24.1/compute-envs/google-cloud-batch)
    * [Google Life Sciences](https://docs.seqera.io/platform/24.1/compute-envs/google-cloud-lifesciences)
    * [HPC (LSF, Slurm, Grid Engine, Altair PBS Pro)](https://docs.seqera.io/platform/24.1/compute-envs/hpc)
    * [Amazon Kubernetes (EKS)](https://docs.seqera.io/platform/24.1/compute-envs/eks)
    * [Google Kubernetes (GKE)](https://docs.seqera.io/platform/24.1/compute-envs/gke)
    * [Hosted Kubernetes](https://docs.seqera.io/platform/24.1/compute-envs/k8s)

### Selecting a default compute environment

If you have more than one **Compute Environment**, you can select which one will be used by default when launching a pipeline.

1. Navigate to your [compute environments](https://docs.seqera.io/platform/24.1/compute-envs/overview).
2. Choose your default environment by selecting the **Make primary** button.

**Congratulations!**

You are now ready to launch workflows with your primary compute environment.

### Launchpad

Launchpad makes it easy for any workspace user to launch a pre-configured pipeline.

![Launchpad](img/overview_launch.png)

A pipeline is a repository containing a Nextflow workflow, a compute environment and workflow parameters.

### Pipeline Parameters Form

Launchpad automatically detects the presence of a `nextflow_schema.json` in the root of the repository and dynamically creates a form where users can easily update the parameters.

!!! info

    The parameter forms view will appear if the pipeline has a Nextflow schema file for the parameters. Please refer to the [Nextflow Schema guide](https://docs.seqera.io/platform/24.1/pipeline-schema/overview) to learn more about the schema file use-cases and how to create them.

This makes it trivial for users without any expertise in Nextflow to enter their workflow parameters and launch.

![Pipeline parameters](img/launch_rnaseq_nextflow_schema.png)

### Adding a new pipeline

Adding a pipeline to the pre-saved workspace launchpad is detailed in full on the [Seqera webpage docs](https://docs.seqera.io/platform/24.1/launch/launchpad#add-new-pipeline).

In brief, these are the steps you need to follow to set up a pipeline.

1. Select the Launchpad button in the navigation bar. This will open the **Launch Form**.
2. Select a [compute environment](https://docs.seqera.io/platform/24.1/compute-envs/overview).
3. Enter the repository of the workflow you want to launch. e.g. <https://github.com/nf-core/rnaseq.git>
4. Select a workflow **Revision number**. The Git default branch (main/master) or `manifest.defaultBranch` in the Nextflow configuration will be used by default.
5. Set the **Work directory** location of the Nextflow work directory. The location associated with the compute environment will be selected by default.
6. Enter the name(s) of each of the Nextflow **Config profiles** followed by the `Enter` key. See the Nextflow [Config profiles](https://www.nextflow.io/docs/latest/config.html#config-profiles) documentation for more details.
7. Enter any workflow parameters in YAML or JSON format. YAML example:

    ```yaml
    reads: "s3://nf-bucket/exome-data/ERR013140_{1,2}.fastq.bz2"
    paired_end: true
    ```

8. Select Launch to begin the pipeline execution.

!!! info

    Nextflow workflows are simply Git repositories and can be changed to any public or private Git-hosting platform. See [Git Integration](https://docs.seqera.io/platform/24.1/git/overview) in the Seqera Platform docs and [Pipeline Sharing](https://www.nextflow.io/docs/latest/sharing.html) in the Nextflow docs for more details.

!!! note

    The credentials associated with the compute environment must be able to access the work directory.

!!! info

    In the configuration, the full path to a bucket must be specified with single quotes around strings and no quotes around booleans or numbers.

!!! tip

    To create your own customized Nextflow Schema for your workflow, see the examples from the `nf-core` workflows that have adopted this approach. For example, [eager](https://github.com/nf-core/eager/blob/2.3.3/nextflow_schema.json) and [rnaseq](https://github.com/nf-core/rnaseq/blob/3.0/nextflow_schema.json).

For advanced settings options check out this [page](https://docs.seqera.io/platform/24.1/launch/launchpad#advanced-settings).

There is also community support available if you get into trouble, join the Nextflow Slack by following this [link](https://www.nextflow.io/slack-invite.html).

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to create an account and login into Seqera Platform
    2. How to configure your compute environment.
    3. How to add, customize, and launch a pipeline with Seqera Platform.

## API

To learn more about using the Seqera Platform API, visit the [API section](https://docs.seqera.io/platform/24.1/api/overview) in the documentation.

## Workspaces and Organizations

Seqera Platform simplifies the development and execution of pipeline by providing a centralized interface for users and organizations.

Each user has a unique **workspace** where they can interact and manage all resources such as workflows, compute environments and credentials. Details of this can be found [here](https://docs.seqera.io/platform/24.1/getting-started/workspace-setup).

Organisations can have multiple workspaces with customized access for specific organisation **members** and **collaborators**.

### Organization resources

You can create your own organization and participant workspace by following the docs at [Seqera](https://docs.seqera.io/platform/24.1/orgs-and-teams/workspace-management).

Seqera Platform allows the creation of multiple organizations, each of which can contain multiple workspaces with shared users and resources. This allows any organization to customize and organize the usage of resources while maintaining an access control layer for users associated with a workspace.

### Organization users

Any user can be added or removed from a particular organization or a workspace and can be allocated a specific access role within that workspace.

The Teams feature provides a way for organizations to group various users and participants together into teams. For example, `workflow-developers` or `analysts`, and apply access control to all the users within this team collectively.

For further information, please refer to the [User Management](https://docs.seqera.io/platform/24.1/orgs-and-teams/organizations) section.

### Setting up a new organization

Organizations are the top-level structure and contain Workspaces, Members, Teams and Collaborators.

To create a new Organization:

1.  Click on the dropdown next to your name and select New organization to open the creation dialog.
2.  On the dialog, fill in the fields as per your organization. The Name and Full name fields are compulsory.

    !!! note

        A valid name for the organization must follow a specific pattern. Please refer to the UI for further instructions.

3.  The rest of the fields such as Description, Location, Website URL and Logo Url are optional.
4.  Once the details are filled in, you can access the newly created organization using the organization’s page, which lists all of your organizations.

    !!! note

        It is possible to change the values of the optional fields either using the Edit option on the organization’s page or by using the Settings tab within the organization page, provided that you are the Owner of the organization.

    !!! tip

        A list of all the included Members, Teams and Collaborators can be found on the organization page.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to create a new organization
    2. How to access the newly created organization
    3. How to change organization settings
