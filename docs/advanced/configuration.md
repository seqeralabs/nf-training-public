# Configuration

This is an aspect of Nextflow that can be confusing. There are multiple ways of loading configuration and parameters into a Nextflow.

This gives us two complications:

- At which location should I be loading a configuration value?
- Given a particular parameter, how do I know where it was set?

## Precedence

1. Parameters specified on the command line (`--something value`)
2. Parameters provided using the `-params-file` option
3. Config file specified using the `-c my_config option`
4. The config file named `nextflow.config` in the current directory
5. The config file named `nextflow.config` in the workflow project directory
6. The config file `$HOME/.nextflow/config`, or `$NXF_HOME/.nextflow/config` when `NXF_HOME` is set (see [`NXF` variable docs](reference/env-vars.html#nextflow-settings))
7. Values defined within the pipeline script itself (e.g. `main.nf`)

!!! note "Precedence is in order of 'distance'"

    A handy guide to understand configuration precedence is in order of 'distance from the command-line invocation'. Parameters specified directly on the CLI `--example foo` are "closer" to the run than configuration specified in the remote repository.

## System-wide configuration - `$HOME/.nextflow/config`

There may be some configuration values that you will want applied on all runs for a given system. These configuration values should be written to `~/.nextflow/config`.

For example - you may have an account on an HPC system and you know that you will always want to submit jobs using the SLURM scheduler when using that machine and always use the Singularity container engine. In this case, your `~/.nextflow/config` file may include:

```groovy
process.executor = 'slurm'
singularity.enable = true
```

These configuration values would be inherited by every run on that system without you needing to remember to specify them each time.

## Overriding for a run - `$PWD/nextflow.config`

Create a chapter example directory:

```
mkdir configuration && cd configuration
```

### Overriding Process Directives

Process directives (listed here) can be overridden using the `process` block. For example, if we wanted to specify that all tasks for a given run should use 2 cpus. In the `nextflow.config` file in the current working directory:

```groovy
process {
    cpus = 2
}
```

... and then run:

```bash
nextflow run rnaseq-nf
```

We can make the configuration more specific by using [process selectors](https://www.nextflow.io/docs/latest/config.html#process-selectors). We can use process names and/or labels to apply process-level directives to specific tasks:

```groovy
process {
    withName: 'RNASEQ:INDEX' {
        cpus = 2
    }
}
```

Glob pattern matching can also be used:

```groovy
process {
    withName: '.*:INDEX' {
        cpus = 2
    }
}
```

### Dynamic Directives

We can specify dynamic directives using closures that are computed as the task is submitted. This allows us to (for example) scale the number of CPUs used by a task by the number of input files.

Give the `FASTQC` process in the [`rnaseq-nf` workflow](https://github.com/nextflow-io/rnaseq-nf)

```groovy
process FASTQC {
    tag "FASTQC on $sample_id"
    conda 'fastqc=0.12.1'
    publishDir params.outdir, mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    fastqc.sh "$sample_id" "$reads"
    """
}
```

we might choose to scale the number of CPUs for the process by the number of files in `reads`:

```groovy
process {
    withName: 'FASTQC' {
        cpus = { reads.size() }
    }
}
```

we can even use the size of the input files. Here we simply sum together the file sizes (in bytes) and use it in the `tag` block:

```groovy
process {
    withName: 'FASTQC' {
        cpus = { reads.size() }
        tag = { "Total size: ${reads*.size().sum() as MemoryUnit}" }
    }
}
```

When we run this:

```
N E X T F L O W  ~  version 23.04.3
Launching `https://github.com/nextflow-io/rnaseq-nf` [fabulous_bartik] DSL2 - revision: d910312506 [master]
 R N A S E Q - N F   P I P E L I N E
 ===================================
 transcriptome: /home/gitpod/.nextflow/assets/nextflow-io/rnaseq-nf/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa
 reads        : /home/gitpod/.nextflow/assets/nextflow-io/rnaseq-nf/data/ggal/ggal_gut_{1,2}.fq
 outdir       : results

executor >  local (4)
[1d/3c5cfc] process > RNASEQ:INDEX (ggal_1_48850000_49020000) [100%] 1 of 1 ✔
[38/a6b717] process > RNASEQ:FASTQC (Total size: 1.3 MB)      [100%] 1 of 1 ✔
[39/5f1cc4] process > RNASEQ:QUANT (ggal_gut)                 [100%] 1 of 1 ✔
[f4/351d02] process > MULTIQC                                 [100%] 1 of 1 ✔

Done! Open the following report in your browser --> results/multiqc_report.html
```

Note that dynamic directives need to be supplied as closures encases in curly braces.

### Retry Strategies

The most common use for dynamic process directives is to enable tasks that fail due to insufficient memory to be resubmitted for a second attempt with more memory.

To enable this, two directives are needed:

- `maxRetries`
- `errorStrategy`

The `errorStrategy` directive determines what action Nextflow should take in the event of a task failure (a non-zero exit code). The available options are:

- `terminate`: Nextflow terminates the execution as soon as an error condition is reported. Pending jobs are killed (default)
- `finish`: Initiates an orderly pipeline shutdown when an error condition is raised, waiting the completion of any submitted job.
- `ignore`: Ignores processes execution errors.
- `retry`: Re-submit for execution a process returning an error condition.

If the `errorStrategy` is "retry", then it will retry up to the value of `maxRetries` times.

If using a closure to specify a directive in configuration, you have access to the `task` variable, which includes the `task.attempt` value - an integer specifying how many times the task has been retried. We can use this to dynamically set values such as `memory` and `cpus`

```groovy
process {
    withName: 'RNASEQ:QUANT' {
        errorStrategy = 'retry'
        maxRetries = 3
        memory = { 2.GB * task.attempt }
        time = { 1.hour * task.attempt }
    }
}
```

!!! note "Configuration vs process"

    When defining values inside configuration, an equals sign `=` is required as shown above.

    When specifying process directives inside the process (in a `.nf` file), no `=` is required:

    ```groovy
    process MULTIQC {
        cpus 2
        // ...
    ```
