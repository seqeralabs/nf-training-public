---
title: Dependencies and containers
description: Fundamentals Nextflow Training Workshop
---

# Manage dependencies and containers

Computational workflows are rarely composed of a single script or tool. More often, they depend on dozens of software components or libraries.

Installing and maintaining such dependencies is a challenging task and a common source of irreproducibility in scientific applications.

To overcome these issues, you can use a container technology that enables software dependencies, i.e. tools and libraries required by a data analysis application, to be encapsulated in one or more self-contained, ready-to-run, immutable container images. These container images can be easily deployed in any platform that supports the container runtime.

Containers can be executed in an isolated manner from the hosting system. Having its own copy of the file system, processing space, and memory management.

!!! info

    Containers were first introduced with kernel 2.6 as a Linux feature known as _Control Groups_ or [Cgroups](https://en.wikipedia.org/wiki/Cgroups).

## Docker basics

Docker is a handy management tool to build, run and share container images.

These container images can be uploaded and published in a centralized repository known as [Docker Hub](https://hub.docker.com), or hosted by other parties, such as [Quay](https://quay.io).

### Run a container

A container can be `run` using the following command:

```bash
docker run <container-name>
```

!!! question "Exercise"

    Run the publicly available `hello-world` container:

    ```bash
    docker run hello-world
    ```

### Pull a container

The `pull` command allows you to download a Docker image without running it. For example:

```bash
docker pull <container-name>
```

You can check if a container has been pulled using the `images` command. For example:

```bash
docker images
```

!!! question "Exercise"

    Pull the publicly available `debian:bullseye-slim` container and check that it has been downloaded:

    ??? Solution

        Pull the container:

        ```bash
        docker pull debian:bullseye-slim
        ```

        Check the container has been downloaded:

        ```bash
        docker images
        ```

### Run a container in interactive mode

Launching a BASH shell in the container allows you to operate in an interactive mode in the containerized operating system. For example:

```bash
docker run -it debian:bullseye-slim bash
```

Once launched, you will notice that it is running as root (!). Use the usual commands to navigate the file system. This is useful to check if the expected programs are present within a container.

To exit from the container, stop the BASH session with the `exit` command.

### Your first Dockerfile

Docker images are created by using a so-called `Dockerfile`, a simple text file containing a list of commands to assemble and configure the image with the software packages required. For example, a Dockerfile to create a container with `curl` installed could be as simple as this:

```dockerfile linenums="1" title="Dockerfile"
FROM debian:bullseye-slim

LABEL image.author.name "Your Name Here"
LABEL image.author.email "your@email.here"

RUN apt-get update && apt-get install -y curl

ENV PATH=$PATH:/usr/games/
```

Once your Dockerfile is ready, you can build the image by using the `build` command. For example:

```bash
docker build -t my-image .
```

Where `my-image` is the user-specified name for the container image you plan to build.

!!! tip

    Don’t miss the dot in the above command.

!!! warning

    The Docker build process automatically copies all files that are located in the current directory to the Docker daemon in order to create the image. This can take a lot of time when big/many files exist. For this reason, it’s important to _always_ work in a directory containing only the files you really need to include in your Docker image. Alternatively, you can use the `.dockerignore` file to select paths to exclude from the build.

When it completes, you can verify that the image has been created by listing all available images:

```bash
docker images
```

!!! question "Exercise"

    Create a Docker image containing `cowsay`.

    ??? Solution

        Use your favorite editor (e.g., `vim` or `nano`) to create a file named `Dockerfile`. Alternatively, run `code Dockerfile` to create a a file named `Dockerfile` in Gitpod. Copy the following content:

        ```dockerfile linenums="1" title="Dockerfile"
        FROM debian:bullseye-slim

        LABEL image.author.name "Your Name Here"
        LABEL image.author.email "your@email.here"

        RUN apt-get update && apt-get install -y curl cowsay

        ENV PATH=$PATH:/usr/games/
        ```

        Build the Docker image based on the Dockerfile by using the following command:

        ```bash
        docker build -t my-image .
        ```

        Try your new container by running this command:

        ```bash
        docker run my-image cowsay Hello Docker!
        ```

### Adding additional software package to the image

Additional tools can be added to the image by adding the appropriate `RUN` command to the Dockerfile.

For example, to add the `salmon` tool to the image, you would add the following line to the bottom of your Dockerfile:

```dockerfile linenums="10" title="Dockerfile"
RUN curl -sSL https://github.com/COMBINE-lab/salmon/releases/download/v1.5.2/salmon-1.5.2_linux_x86_64.tar.gz | tar xz \
&& mv /salmon-*/bin/* /usr/bin/ \
&& mv /salmon-*/lib/* /usr/lib/
```

You will then need to save the file and build the image again with the same command as before:

```bash
docker build -t my-image .
```

!!! question "Exercise"

    Add the Salmon tool to your Docker file and rebuild the image.

    ??? Solution

        Open your Dockerfile and add the following lines to the bottom of the file:

        ```dockerfile linenums="10" title="Dockerfile"
        RUN curl -sSL https://github.com/COMBINE-lab/salmon/releases/download/v1.5.2/salmon-1.5.2_linux_x86_64.tar.gz | tar xz \
        && mv /salmon-*/bin/* /usr/bin/ \
        && mv /salmon-*/lib/* /usr/lib/
        ```

        Save the file and build the image again with the same command as before:

        ```bash
        docker build -t my-image .
        ```

        You will notice that it creates a new Docker image with the same name **but** with a different image ID.

### Run Salmon in the container

!!! tip

    If you didn't complete the steps above, use the 'rnaseq-nf' image used elsewhere in these materials by specifying `nextflow/rnaseq-nf` in place of `my-image` in the following examples.

You can run the software installed in the container by using the `run` command. For example, you can check that Salmon is running correctly in the container generated above by using the following command:

```bash
docker run my-image salmon --version
```

You can even launch a container in an interactive mode by using the following command:

```bash
docker run -it my-image bash
```

Use the `exit` command to terminate the interactive session.

### File system mounts

Containers run in a completely separate file system and it cannot access the hosting file system by default.

For example, running the following command that is attempting to generate a genome index using the Salmon tool will fail because Salmon cannot access the input file:

```bash
docker run my-image \
    salmon index -t $PWD/data/ggal/transcriptome.fa -i transcript-index
```

To mount a filesystem within a Docker container, you can use the `--volume` command-line option when running the container. Its argument consists of two fields separated by a colon (:):

-   Host source directory path
-   Container target directory path

For example:

```bash
docker run --volume $PWD/data/ggal/transcriptome.fa:/transcriptome.fa my-image \
    salmon index -t /transcriptome.fa -i transcript-index
```

!!! warning

    The generated `transcript-index` directory is still not accessible in the **host** file system.

An easier way to mount file systems is to mount a parent directory to an identical directory in the container. This allows you to use the same path when running it in the container. For example:

```bash
docker run --volume $PWD:$PWD --workdir $PWD my-image \
    salmon index -t $PWD/data/ggal/transcriptome.fa -i transcript-index
```

Or set a folder you want to mount as an environmental variable, called `DATA`:

```bash
DATA=/workspace/gitpod/nf-training/data
docker run --volume $DATA:$DATA --workdir $PWD my-image \
    salmon index -t $PWD/data/ggal/transcriptome.fa -i transcript-index
```

You can check the content of the `transcript-index` folder by entering the command:

```bash
ls -la transcript-index
```

!!! note

    Note that the permissions for files created by the Docker execution is `root`.

### Upload the container in the Docker Hub (optional)

You can also publish your container in the Docker Hub to share it with other people.

Create an account on the <https://hub.docker.com> website. Then from your shell terminal run the following command, entering the user name and password you specified when registering in the Hub:

```bash
docker login
```

Rename the image to include your Docker user name account:

```bash
docker tag my-image <user-name>/my-image
```

Finally push it to the Docker Hub:

```bash
docker push <user-name>/my-image
```

After that anyone will be able to download it by using the command:

```bash
docker pull <user-name>/my-image
```

Note how after a pull and push operation, Docker prints the container digest number e.g.

```console title="Output"
Digest: sha256:aeacbd7ea1154f263cda972a96920fb228b2033544c2641476350b9317dab266
Status: Downloaded newer image for nextflow/rnaseq-nf:latest
```

This is a unique and immutable identifier that can be used to reference a container image in a univocally manner. For example:

```bash
docker pull nextflow/rnaseq-nf@sha256:aeacbd7ea1154f263cda972a96920fb228b2033544c2641476350b9317dab266
```

### Run a Nextflow script using a Docker container

The simplest way to run a Nextflow script with a Docker image is using the `-with-docker` command-line option:

```bash
nextflow run script2.nf -with-docker my-image
```

As seen in the last section, you can also configure the Nextflow config file (`nextflow.config`) to select which container image to use instead of having to specify it as a command-line argument every time.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to `run` a docker container
    2. How to `pull` a docker container
    3. How to create your own docker container using a `Dockerfile`
    4. How to add additional software packages to your container
    5. How to use your own container when running a nextflow script

## Singularity

[Singularity](http://singularity.lbl.gov) is a container runtime designed to work in high-performance computing data centers, where the usage of Docker is generally not allowed due to security constraints.

Singularity implements a container execution model similar to Docker. However, it uses a completely different implementation design.

A Singularity container image is archived as a plain file that can be stored in a shared file system and accessed by many computing nodes managed using a batch scheduler.

### Create a Singularity images

Singularity images are created using a `Singularity` file in a similar manner to Docker but using a different syntax.

```singularity title="Singularity" linenums="1"
Bootstrap: docker
From: debian:bullseye-slim

%environment
export PATH=$PATH:/usr/games/

%labels
AUTHOR <your name>

%post

apt-get update && apt-get install -y locales-all curl cowsay
curl -sSL https://github.com/COMBINE-lab/salmon/releases/download/v1.0.0/salmon-1.0.0_linux_x86_64.tar.gz | tar xz \
&& mv /salmon-*/bin/* /usr/bin/ \
&& mv /salmon-*/lib/* /usr/lib/
```

Once you have saved the `Singularity` file, you can create the image with the build command:

```bash
sudo singularity build my-image.sif Singularity
```

!!! warning

    The `build` command requires `sudo` permissions. A common workaround consists of building the image on a local workstation and then deploying it in the cluster by copying the image file.

### Running a container

You can run your container using the `exec` command:

```bash
singularity exec my-image.sif cowsay 'Hello Singularity'
```

By using the `shell` command you can enter in the container in interactive mode:

```bash
singularity shell my-image.sif
```

Once in the container instance run the following command:

```bash
touch hello.txt
ls -la
```

!!! info

    Note how the files on the host environment are shown. Singularity automatically mounts the host `$HOME` directory and uses the current work directory.

### Import a Docker image

An easier way to create a Singularity container without requiring `sudo` permission and boosting the containers interoperability is to import a Docker container image by pulling it directly from a Docker registry. For example:

```bash
singularity pull docker://debian:bullseye-slim
```

The above command automatically downloads the Debian Docker image and converts it to a Singularity image in the current directory with the name `debian-jessie.simg`.

### Run a Nextflow script using a Singularity container

As with Docker, Nextflow allows the transparent usage of Singularity containers.

Simply enable the use of the Singularity engine in place of Docker in the Nextflow command line by using the `-with-singularity` command-line option:

```bash
nextflow run script7.nf -with-singularity  nextflow/rnaseq-nf
```

As before, the Singularity container can also be provided in the Nextflow config file. We’ll see how to do this later.

### The Singularity Container Library

The authors of Singularity, [SyLabs](https://www.sylabs.io/) have their [own repository](https://cloud.sylabs.io) of Singularity containers.

In the same way that you can push Docker images to Docker Hub, you can upload Singularity images to the Singularity Library.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to create and run a Singularity container
    2. How to Run a Nextflow script using a Singularity container
    3. How to access the the Singularity container library

## Conda packages

Conda is a popular package and environment manager. The built-in support for Conda allows Nextflow workflows to automatically create and activate the Conda environment(s), given the dependencies specified by each process.

In this Gitpod environment, conda is already installed.

### Using conda

A Conda environment is defined using a YAML file, which lists the required software packages.

To use conda, you need to initiate conda and open a new terminal by running bash:

```bash
conda init
bash
```

There is already a file named `env.yml` in the `nf-training` folder as an example. Its content is shown below:

```yaml title="nf-training/env.yml" linenums="1"
--8<-- "nf-training/env.yml"
```

Given the `env.yml` recipe file, the environment can be created using the command shown below.

```bash
conda env create --file env.yml
```

The `conda env create` command may take several minutes, as conda tries to resolve dependencies of the desired packages at runtime, and then downloads everything that is required.

You can check if the environment was created successfully with the command shown below:

```bash
conda env list
```

This output will look something like this:

```console title="Output"
# conda environments:
#
base                  *  /opt/conda
nf-tutorial              /opt/conda/envs/nf-tutorial
```

To enable the environment, you can use the `activate` command:

```bash
conda activate nf-tutorial
```

Nextflow is able to manage the activation of a Conda environment when its directory is specified using the `-with-conda` option (using the same path shown in the `list` function. For example:

```bash
nextflow run script7.nf -with-conda /opt/conda/envs/nf-tutorial
```

!!! info

    When creating a Conda environment with a YAML recipe file, Nextflow automatically downloads the required dependencies, builds the environment and activates it.

This makes easier to manage different environments for the processes in the workflow script.

See the [docs](https://www.nextflow.io/docs/latest/conda.html) for further details.

### Create and use conda-like environments using micromamba

Another way to build conda-like environments is through a `Dockerfile` and [`micromamba`](https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html).

`micromamba` is a fast and robust package for building small conda-based environments.

This saves having to build a conda environment each time you want to use it (as outlined in previous sections).

To do this, you simply require a `Dockerfile` and you use micromamba to install the packages. However, a good practice is to have a YAML recipe file.

Using the same `env.yml` from above, you can write a Dockerfile with `micromamba` installing the packages from the recipe file. For example:

```dockerfile title="Dockerfile" linenums="1"
FROM mambaorg/micromamba:0.25.1

LABEL image.author.name "Your Name Here"
LABEL image.author.email "your@email.here"

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/env.yml

RUN micromamba create -n nf-tutorial

RUN micromamba install -y -n nf-tutorial -f /tmp/env.yml && \
    micromamba clean --all --yes

ENV PATH /opt/conda/envs/nf-tutorial/bin:$PATH
```

The above `Dockerfile` takes the parent image _mambaorg/micromamba_, installs a `conda` environment using `micromamba`, and then installs `salmon`, `fastqc`, and `multiqc`.

!!! question "Exercise"

    Execute `script7.nf` using your own micromamba `Dockerfile` that you have pushed to your Docker hub repo.

    !!! warning

        Building a Docker container and pushing to your personal repo can take &gt;10 minutes.

    ??? Solution

        Make a file called `Dockerfile` in the current directory.

        ```dockerfile title="Dockerfile" linenums="1"
        FROM mambaorg/micromamba:0.25.1

        LABEL image.author.name "Your Name Here"
        LABEL image.author.email "your@email.here"

        COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/env.yml

        RUN micromamba create -n nf-tutorial

        RUN micromamba install -y -n nf-tutorial -f /tmp/env.yml && \
        micromamba clean --all --yes

        ENV PATH /opt/conda/envs/nf-tutorial/bin:$PATH
        ```

        Build the image:

        ```bash
        docker build -t my-image .
        ```

        Publish the Docker image to your online Docker account.

        ```bash
        docker login
        docker tag my-image <myrepo>/my-image
        docker push <myrepo>/my-image
        ```

        `<myrepo>` needs to be replaced with your own Docker ID, without the _&lt;_ and _&gt;_ characters.

        `my-image` can be replaced with any name you choose. As good practice, choose something memorable and ensure the name matches the name you used in the previous command.

        Add the container image name to the `nextflow.config` file.

        For example, remove the following from the `nextflow.config`:

        ```groovy title="nextflow.config" linenums="1"
        process.container = 'nextflow/rnaseq-nf'
        ```

        Replace it with:

        ```groovy title="nextflow.config" linenums="1"
        process.container = '<myrepo>/my-image'
        ```

        Trying running Nextflow, For example:

        ```bash
        nextflow run script7.nf -with-docker
        ```

        Nextflow should now be able to find `salmon` to run the process.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to create conda-like environments using micromamba
    2. How to use use conda-like environments using micromamba

## BioContainers

Another useful resource linking together Bioconda and containers is the [BioContainers](https://biocontainers.pro) project. BioContainers is a community initiative that provides a registry of container images for every Bioconda recipe.

With BioContainers, you don’t need to create your own container image for the tools you want, and you don’t need to use conda or micromamba to install the packages. Instead, BioContainers provides you with a Docker image containing the program you need. For example, you can pull the container image of fastqc using BioContainers with:

```bash
docker pull biocontainers/fastqc:v0.11.5
```

You can check the registry for the packages you want at [BioContainers official website](https://biocontainers.pro/registry). For finding multi-tools container images, check their [Multi-package images](https://biocontainers.pro/multipackage).

Contrary to other registries that will pull the latest image when no tag (version) is provided, you must specify a tag when pulling BioContainers (after a colon `:`, e.g., `fastqc:v0.11.5`). Check the tags within the registry and pick the tag that best suits your needs.

You can also install `galaxy-util-tools` and search for _mulled_ containers in your CLI. You'll find instructions below, using conda to install the tool.

```bash
conda create -n galaxy-tool-util -y galaxy-tool-util # Create a new environment with 'galaxy-tool-util' installed
conda activate galaxy-tool-util
mulled-search --destination quay singularity --channel bioconda --search bowtie samtools | grep mulled
```

!!! tip

    You can have more complex definitions within your process block by letting the appropriate container image or conda package be used depending on if the user selected singularity, Docker or conda to be used. You can click [here](https://nf-co.re/docs/contributing/modules#software-requirements) for more information and [here](https://github.com/nf-core/modules/blob/61f68913fefc20241ceccb671b104230b2d775d7/modules/bowtie2/align/main.nf#L6-L9) for an example.

!!! question "Exercise"

    During the earlier RNA-Seq tutorial (script2.nf), you created an index with the salmon tool. Given you do not have salmon installed locally in the machine provided by Gitpod, you had to either run it with `-with-conda` or `-with-docker`. Your task now is to run it again `-with-docker`, but without creating your own container image. Instead, use the BioContainers image for salmon 1.7.0.


    ??? Solution

        ```bash
        nextflow run script2.nf -with-docker quay.io/biocontainers/salmon:1.7.0--h84f40af_0
        ```

        Instead of supplying one big container for a complete workflow, separate containers can be used for each process in a workflow. This way, you can quickly add, update, or remove a tool from your workflow without having to rebuild the entire workflow container.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. What Biocontainers are and where to find them
    2. How to use Biocontainers in your Nextflow workflow

## Software directives

Directives are optional settings that affect the execution of the current process.

They must be entered at the top of the process body, before any other declaration blocks

### Container directives

The `container` directive allows you to execute the process script in a Docker container.

```groovy title="example.nf" linenums="1"
process FASTQC {
    container 'biocontainers/fastqc:v0.11.5'
    tag "FASTQC on $sample_id"
    ...
```

### Conda directives

Similarly, the `conda` directive allows for the definition of the process dependencies using the Conda package manager.

```groovy title="example.nf" linenums="1"
process FASTQC {
    conda 'fastqc=0.11.5'
    tag "FASTQC on $sample_id"
    ...
```

Nextflow automatically sets up an environment for the given package names listed by in the conda directive.

!!! question "Exercise"

    The tools `fastqc` and `salmon` are both available in Biocontainers (`biocontainers/fastqc:v0.11.5` and `quay.io/biocontainers/salmon:1.7.0--h84f40af_0`, respectively). Add the appropriate `container` directives to the `FASTQC` and `QUANTIFICATION` processes in `script5.nf` to use Seqera Containers instead of the container image you have been using in this training.

    !!! tip "Hint"

        Temporarily comment out the line `#!groovy process.container = 'nextflow/rnaseq-nf'` in the `nextflow.config` file to make sure the processes are using the BioContainers that you set, and not the container image you have been using in this training.

    ??? Solution

        Add the container directive with the appropriate BioContainers to the `FASTQC` and `QUANTIFICATION` processes in `script5.nf`:

        ```groovy title="script5.nf" linenums="52"
        process FASTQC {
            container 'biocontainers/fastqc:v0.11.5'
            tag "FASTQC on $sample_id"
        ...
        ```

        and

        ```groovy title="script5.nf" linenums="35 git "
        process QUANTIFICATION {
            tag "Salmon on $sample_id"
            container 'quay.io/biocontainers/salmon:1.7.0--h84f40af_0'
            publishDir params.outdir, mode: 'copy'
        ...
        ```


        With these changes, you should be able to run the workflow with BioContainers by running the following in the command line:

        ```bash
        nextflow run script5.nf
        ```

        You can check the `.command.run` file in the work directory and ensure that the run line contains the correct Biocontainers.

!!! cboard-list-2 "Summary"

    In this step you have learned:

    1. How to add software with directives
