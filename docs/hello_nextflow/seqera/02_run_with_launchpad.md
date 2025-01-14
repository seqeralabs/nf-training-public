## 2 Using Seqera Platform Launchpad to run Nextflow workflows

So far we've been running Nextflow workflows on our local machine using the command line interface but sending the logs to Seqera Platform for monitoring and visualization.
Next we want to start using Seqera Platform to launch Nextflow workflows on our behalf.

!!! Note "Community Showcase"

    Having a compute environment capable of running Nextflow workflows configured in Seqera Platform is normally a prerequisite for this task.
    But we want to see how it works before we put in that effort, so we'll start by launching a job in community/showcase workspace which has a compute environment already set up.

!!! tip "Trainer Tip"

    Launch a test run of the seqeralabs/nf-hello-genomics pipeline in the community/showcase workspace prior to starting this session, so you'll have a recent run for participants to inspect.

### 2.1. Navigate to the community/showcase workspace

Seqera Platform has a concept of [**organizations**](https://docs.seqera.io/platform/latest/orgs-and-teams/organizations) and [**workspaces**](https://docs.seqera.io/platform/latest/orgs-and-teams/workspace-management) which are used to organize and share [pipelines](https://docs.seqera.io/platform/latest/launch/launchpad), [compute environments](https://docs.seqera.io/platform/latest/compute-envs/overview), [data](https://docs.seqera.io/platform/latest/data/data-explorer), [credentials](https://docs.seqera.io/platform/latest/credentials/overview), and more.
The `community/showcase` workspace is a public workspace where you can see some example pipelines and compute environments.
Each user has an allotted amount of free compute to use in this workspace.

Click on your username in the top left corner of the screen to bring up the list of organizations and workspaces you have access to.
Select the `community/showcase` workspace.

### 2.2. Launch a test run of seqeralabs/nf-hello-genomics pipeline

In the `community/showcase` workspace, you will see a list of pipelines that have been set up by the workspace owner for you to run.
Follow these steps to launch a test run of a pipeline:

![Launchpad](seqera/img/launchpad.gif)

1. Find the `nf-hello-genomics` pipeline in the list of pipelines (this is the same workflow you may have encountered in the [Hello Genomics](../06_hello_config.md) module).
2. Click on the `Launch` button to bring up the launch form.
3. Change the "Workflow run name" to "<username>-hellogenomics-test".
4. Click "Next" to bring up the parameters form.
5. Take a look at the options. Feel free to take a moment to understand them, referring to [Hello Genomics](../06_hello_config.md) as needed.
6. Click on "Next" to inspect the advanced configuration.
7. Click "Launch" to start the pipeline!

!!! Tip

    In the advanced configuration, you'll see a section named "Pre-run script" with a script similar to the following:

    ```bash
    export NXF_FILE_ROOT=s3://nf-tower-bucket/scratch/$TOWER_WORKFLOW_ID
    ```

    This is what ensures that everyone's pipeline will write to a unique location in cloud storage despite all having the `outdir` parameter set to `./results`.

### 2.3. Monitor the pipeline run

After launching the pipeline, you will be taken to the pipeline run page where you can monitor the progress of the pipeline.
It may take some time for the pipeline to start running while AWS Batch spins up the needed resources, so go to the "Runs" tab above the pipeline and open a recent completed (or failed) run by one of your "teammates" in the community.

### 2.4. Inspect a pipeline run

Scroll down to find the list of tasks that were executed in the pipeline run.
For example, by searching for `GATK_JOINTGENOTYPING` we can find the main genotyping process that was executed as part of the pipeline.

Click on the task to see the task details:

![Task details](seqera/img/task_details.png)

1. Find the following details on the "About" page for the the task you're inspecting:

    - [ ] How long did the task script run (not including scheduling time)?
    - [ ] How many CPUs were allocated to the task?
    - [ ] What was the virtual machine type that the task ran on?
    - [ ] What was the estimated cost of the task?

2. Explore the Execution Log tab. What information is available here?

3. Explore the Data Explorer tab. Note that the work directory structure we've seen during local runs is replicated here in cloud storage!

### Takeaway

You have learned how to:

- Switch between organizations and workspaces in Seqera Platform.
- Launch a Nextflow pipeline that ran in the cloud using Seqera Platform.
- Monitor the progress of the pipeline run.
- Inspect the details of a task that was executed as part of the pipeline.

### Next steps

In the next section, we will learn how to set up a compute environment in Seqera Platform to run our own Nextflow workflows.
