# Local installation

If you **can not** access Gitpod you can also install everything locally.

Some requirements may be different depending on your local machine.

## Requirements

Nextflow can be used on any POSIX-compatible system (Linux, macOS, Windows Subsystem for Linux, etc.).

**Requirements**

-   Bash
-   [Java 11 (or later, up to 21)](https://www.oracle.com/technetwork/java/javase/downloads/index.html)
-   [Git](https://git-scm.com/)
-   [Docker](https://docs.docker.com/get-docker/)

**Optional requirements**

-   [Singularity](https://github.com/sylabs/singularity) 2.5.x (or later)
-   [Conda](https://conda.io/) 4.5 (or later)
-   [Graphviz](http://www.graphviz.org/)
-   [AWS CLI](https://aws.amazon.com/cli/)
-   A configured AWS Batch computing environment

## Download Nextflow

Execute this command in your terminal:

```bash
wget -qO- https://get.nextflow.io | bash
```

Alternatively, you could use the `curl` command:

```bash
curl -s https://get.nextflow.io | bash
```

Next, ensure that the downloaded binary is executable:

```bash
chmod +x nextflow
```

Finally, ensure the `nextflow` executable is in your `$PATH`. The executable could be in `/usr/local/bin`, `/bin/`, etc.

## Docker

Ensure you have Docker Desktop running on your machine. You can download Docker [here](https://docs.docker.com/get-docker/).

## Training material

You can view the training material [here](https://training.nextflow.io/).

To download the material, execute this command:

```bash
git clone https://github.com/nextflow-io/training.git
```

Then `cd` into the `nf-training` directory.

## Checking your installation

Check that you have correctly installed `nextflow` by running the following command:

```bash
nextflow info
```

This should print the current version, system, and runtime.

!!! question "Exercise"

    To test that the environment is working correctly, execute the following command:

    ```bash
    nextflow info
    ```

    This should come up with the Nextflow version and runtime information:

    ```console
    Version: 23.10.1 build 5891
    Created: 12-01-2024 22:01 UTC
    System: Linux 6.1.75-060175-generic
    Runtime: Groovy 3.0.19 on OpenJDK 64-Bit Server VM 11.0.1-internal+0-adhoc..src
    Encoding: UTF-8 (UTF-8)
    ```
