# Part 1: More Containers

[TODO]

---

## 1. How to find or make container images

Some software developers provide container images for their software that are available on container registries like Docker Hub, but many do not.
In this optional section, we'll show you to two ways to get a container image for tools you want to use in your Nextflow pipelines: using Seqera Containers and building the container image yourself.

You'll be getting/building a container image for the `quote` pip package, which will be used in the exercise at the end of this section.

### 1.1. Get a container image from Seqera Containers

Seqera Containers is a free service that builds container images for pip and conda (including bioconda) installable tools.
Navigate to [Seqera Containers](https://www.seqera.io/containers/) and search for the `quote` pip package.

![Seqera Containers](img/seqera-containers-1.png)

Click on "+Add" and then "Get Container" to request a container image for the `quote` pip package.

![Seqera Containers](img/seqera-containers-2.png)

If this is the first time a community container has been built for this version of the package, it may take a few minutes to complete.
Click to copy the URI (e.g. `community.wave.seqera.io/library/pip_quote:ae07804021465ee9`) of the container image that was created for you.

You can now use the container image to run the `quote` command and get a random saying from Grace Hopper.

```bash
docker run --rm community.wave.seqera.io/library/pip_quote:ae07804021465ee9 quote "Grace Hopper"
```

Output:

```console title="Output"
Humans are allergic to change. They love to say, 'We've always done it
this way.' I try to fight that. That's why I have a clock on my wall
that runs counter-clockwise.
```

### 1.2. Build the container image yourself

Let's use some build details from the Seqera Containers website to build the container image for the `quote` pip package ourselves.
Return to the Seqera Containers website and click on the "Build Details" button.

The first item we'll look at is the `Dockerfile`, a type of script file that contains all the commands needed to build the container image.
We've added some explanatory comments to the Dockerfile below to help you understand what each part does.

```Dockerfile title="Dockerfile"
# Start from the micromamba base docker image
FROM mambaorg/micromamba:1.5.10-noble
# Copy the conda.yml file into the container
COPY --chown=$MAMBA_USER:$MAMBA_USER conda.yml /tmp/conda.yml
# Install various utilities for Nextflow to use and the packages in the conda.yml file
RUN micromamba install -y -n base -f /tmp/conda.yml \
    && micromamba install -y -n base conda-forge::procps-ng \
    && micromamba env export --name base --explicit > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y
# Run the container as the root user
USER root
# Set the PATH environment variable to include the micromamba installation directory
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
```

The second item we'll look at is the `conda.yml` file, which contains the list of packages that need to be installed in the container image.

```conda.yml title="conda.yml"
channels:
- conda-forge
- bioconda
dependencies:
- pip
- pip:
  - quote==3.0.0 #
```

Copy the contents of these files into the stubs located in the `containers/build` directory, then run the following command to build the container image yourself.

!!! Note

    We use the `-t quote:latest` flag to tag the container image with the name `quote` and the tag `latest`.
    We will be able to use this tag to refer to the container image when running it on this system.

```bash
docker build -t quote:latest containers/build
```

After it has finished building, you can run the container image you just built.

```bash
docker run --rm quote:latest quote "Margaret Oakley Dayhoff"
```

### Takeaway

You've learned two different ways to get a container image for a tool you want to use in your Nextflow pipelines: using Seqera Containers and building the container image yourself.

### What's next?

You have everything you need to continue to the [next chapter](./04_hello_genomics.md) of this training series.
You can also continue on with an optional exercise to fetch quotes on computer/biology pioneers using the `quote` container and output them using the `cowsay` container.

---

## 2. Make the cow quote famous scientists

This section contains some stretch exercises, to practice what you've learned so far.
Doing these exercises is _not required_ to understand later parts of the training, but provide a fun way to reinforce your learnings by figuring out how to make the cow quote famous scientists.

```console title="cowsay-output-Grace-Hopper.txt"
  _________________________________________________
 /                                                 \
| Humans are allergic to change. They love to       |
| say, 'We've always done it this way.' I try to fi |
| ght that. That's why I have a clock on my wall th |
| at runs counter-clockwise.                        |
| -Grace Hopper                                     |
 \                                                 /
  =================================================
                                                 \
                                                  \
                                                    ^__^
                                                    (oo)\_______
                                                    (__)\       )\/\
                                                        ||----w |
                                                        ||     ||
```

### 2.1. Modify the `hello-containers.nf` script to use a getQuote process

We have a list of computer and biology pioneers in the `containers/data/pioneers.csv` file.
At a high level, to complete this exercise you will need to:

-   Modify the default `params.input_file` to point to the `pioneers.csv` file.
-   Create a `getQuote` process that uses the `quote` container to fetch a quote for each input.
-   Connect the output of the `getQuote` process to the `cowsay` process to display the quote.

For the `quote` container image, you can either use the one you built yourself in the previous stretch exercise or use the one you got from Seqera Containers .

!!! Hint

    A good choice for the `script` block of your getQuote process might be:
        ```groovy
        script:
            def safe_author = author.tokenize(' ').join('-')
            """
            quote "$author" > quote-${safe_author}.txt
            echo "-${author}" >> quote-${safe_author}.txt
            """
        ```

You can find a solution to this exercise in `containers/solutions/hello-containers-4.1.nf`.

### 2.2. Modify your Nextflow pipeline to allow it to execute in `quote` and `sayHello` modes.

Add some branching logic using to your pipeline to allow it to accept inputs intended for both `quote` and `sayHello`.
Here's an example of how to use an `if` statement in a Nextflow workflow:

```groovy title="hello-containers.nf"
workflow {
    if (params.quote) {
        ...
    }
    else {
        ...
    }
    cowSay(text_ch)
}
```

!!! Hint

    You can use `new_ch = processName.out` to assign a name to the output channel of a process.

You can find a solution to this exercise in `containers/solutions/hello-containers-4.2.nf`.

### Takeaway

You know how to use containers in Nextflow to run processes, and how to build some branching logic into your pipelines!

### What's next?

Celebrate, take a stretch break and drink some water!

When you are ready, move on to Part 3 of this training series to learn how to apply what you've learned so far to a more realistic data analysis use case.
