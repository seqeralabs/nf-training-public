# Orientation

The Gitpod environment contains all the software, code and data necessary to work through this training course, so you don't need to install anything yourself.
However, you do need a (free) account to log in, and you should take a few minutes to familiarize yourself with the interface.

If you have not yet done so, please follow [this link](../../envsetup/) before going any further.

## Materials provided

Throughout this training course, we'll be working in the `hello-nextflow/` directory, which loads by default when you open the Gitpod workspace.
This directory contains all the code files, test data and accessory files you will need.

Feel free to explore the contents of this directory; the easiest way to do so is to use the file explorer on the left-hand side of the Gitpod workspace.
Alternatively, you can use the `tree` command.
Throughout the course, we use the output of `tree` to represent directory structure and contents in a readable form, sometimes with minor modifications for clarity.

Here we generate a table of contents to the second level down:

```bash
tree . -L 2
```

If you run this inside `hello-nextflow`, you should see the following output:

```console title="Directory contents"
.
├── containers
│   ├── build
│   ├── data
│   ├── results
│   └── scripts
├── data
│   ├── bam
│   ├── greetings.csv
│   ├── ref
│   ├── sample_bams.txt
│   └── samplesheet.csv
├── hello-config
│   ├── demo-params.json
│   ├── main.nf
│   └── nextflow.config
├── hello-containers.nf
├── hello-genomics.nf
├── hello-modules
│   ├── demo-params.json
│   ├── main.nf
│   └── nextflow.config
├── hello-nf-core
│   ├── data
│   └── solution
├── hello-nf-test
│   ├── demo-params.json
│   ├── main.nf
│   ├── modules
│   └── nextflow.config
├── hello-operators.nf
├── hello-world.nf
├── nextflow.config
└── solutions
    ├── hello-config
    ├── hello-genomics
    ├── hello-modules
    ├── hello-nf-test
    ├── hello-operators
    └── hello-world

18 directories, 17 files
```

!!!note

    Don't worry if this seems like a lot; we'll go through the relevant pieces at each step of the course.
    This is just meant to give you an overview.

**Here's a summary of what you should know to get started:**

-   **The `.nf` files** are workflow scripts that are named based on what part of the course they're used in.

-   **The `hello-*` directories** are directories used in the later Parts of the course where we are working with more than just one workflow file.

-   **The file `nextflow.config`** is a configuration file that sets minimal environment properties.
    You can ignore it for now.

-   **The `data` directory** contains the input data we'll use in most of the course. The dataset is described in detail in Part 3, when we introduce it for the first time.

-   **The `solutions` directory** contains the completed workflow scripts that result from each step of the course.
    They are intended to be used as a reference to check your work and troubleshoot any issues.
    The name and number in the filename correspond to the step of the relevant part of the course.
    For example, the file `hello-world-4.nf` is the expected result of completing steps 1 through 4 of Part 1: Hello World.

!!!tip

    If for whatever reason you move out of this directory, you can always run this command to return to it:

    ```bash
    cd /workspace/gitpod/hello-nextflow
    ```

Now, to begin the course, click on the arrow in the bottom right corner of this page.
