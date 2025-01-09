# Orientation

This workshop should be completed using the [Nextflow Training Gitpod Environment](https://gitpod.io/#https://github.com/nextflow-io/training).

## Getting started

You will need to move into the `troubleshoot` folder.

You will need to copy and unzip the data required for this training.

!!! question "Exercise"

    Use the following command to switch to the empty `troubleshoot` folder:

    ```bash
    cd /workspace/gitpod/troubleshoot
    cp -r /workspace/gitpod/hello-nextflow/data/ .
    tar -zxvf data/ref.tar.gz -C data/
    ```

To check everything is working as expected you can run the `hello-gatk.nf` script located in the `troubleshoot` folder.

If all of the data has been copied and unzipped correctly you should see the pipeline execute three processes:

-   `SAMTOOLS_INDEX`
-   `GATK_HAPLOTYPECALLER`
-   `GATK_JOINTGENOTYPING`
