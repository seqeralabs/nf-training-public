# Custom modules

nf-core offers a comprehensive set of modules that have been created and curated by the community. However, as a developer, you may be interested in bespoke pieces of software that are not apart of the nf-core repository or customizing a module that already exists.

There are multiple ways to approach this.

## Adding a local module

Local modules are

!!! question "Exercise"

    Add a `CUSTOM_FASTQC` process to your pipeline.

    First, create a file named `custom_fastqc.nf` in a `modules/local/` folder:

    ```
    code /modules/local/custom_fastqc.nf
    ```

    Second, add the following `CUSTOM_FASTQC` process to your new `custom_fastqc.nf` file:

    ```
    process CUSTOM_FASTQC {
        tag "$meta.id"
        label 'process_medium'

        conda "${moduleDir}/environment.yml"
        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0' :
            'biocontainers/fastqc:0.12.1--hdfd78af_0' }"

        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path("*.html"), emit: html
        tuple val(meta), path("*.zip") , emit: zip
        path  "versions.yml"           , emit: versions

        when:
        task.ext.when == null || task.ext.when

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        // Make list of old name and new name pairs to use for renaming in the bash while loop
        def old_new_pairs = reads instanceof Path || reads.size() == 1 ? [[ reads, "${prefix}.${reads.extension}" ]] : reads.withIndex().collect { entry, index -> [ entry, "${prefix}_${index + 1}.${entry.extension}" ] }
        def rename_to = old_new_pairs*.join(' ').join(' ')
        def renamed_files = old_new_pairs.collect{ old_name, new_name -> new_name }.join(' ')

        """
        printf "%s %s\\n" $rename_to | while read old_name new_name; do
            [ -f "\${new_name}" ] || ln -s \$old_name \$new_name
        done

        fastqc \\
            --threads $task.cpus \\
            $renamed_files

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
        END_VERSIONS
        """
    }
    ```

    Third, add the following to your `conf/modules.config` file to specify how files should be named and where they should be saved:

    ```console title="conf/modules.config" "39"
    withName: 'CUSTOM_FASTQC' {
        ext.args        = '--quiet'
        ext.prefix      = { "TRIMMED_${meta.id}" }
        publishDir = [
            path: { "${params.outdir}/fastqc/${meta.id}" },
            mode: params.publish_dir_mode,
            pattern: "*.{html,json}"
        ]
    }
    ```

    Fourth, include the `CUSTOM_FASTQC` process in your workflow block:

    ```groovy title="workflows/mypipeline.nf" linenums="13"
    include { CUSTOM_FASTQC          } from '../modules/local/custom_fastqc'
    ```

    Finally, add the `CUSTOM_FASTQC` process to your workflow block. As the `ch_trimmed` channel will only be created if the `SEQTK_TRIM` was executed, the same `if` statement is used here to prevent errors.

    ```groovy title="workflows/mypipeline.nf" linenums="51"
    //
    // MODULE: Run CUSTOM_FASTQC
    //
    if (!params.skip_trim) {
        CUSTOM_FASTQC (
            ch_trimmed
        )
        ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_FASTQC.out.zip.collect{it[1]})
        ch_versions = ch_versions.mix(CUSTOM_FASTQC.out.versions.first())
    }
    ```

    Execute your pipeline again and check the results to see if your custom module is executed and the results are saved:

    ```bash
    nextflow run nf-core-myfirstpipeline -profile test,singularity --outdir results_customfastqc
    ```

## Patching modules

Although nf-core modules are written to be flexible you may want to modify them to better fit your purpose.

nf-core components (modules and subworkflows) are tracked in the `modules.json` in the base repository. Information about each component (name, branch, git sha, and installation) are tracked and compared to the repository where the component came from.

```json title="modules.json" linenums="1"
{
    "name": "nf-core/demo",
    "homePage": "https://github.com/nf-core/demo",
    "repos": {
        "https://github.com/nf-core/modules.git": {
            "modules": {
                "nf-core": {
                    "fastqc": {
                        "branch": "master",
                        "git_sha": "285a50500f9e02578d90b3ce6382ea3c30216acd",
                        "installed_by": ["modules"]
                    },
                <truncated>
```

The `modules.json` is used during linting tests. If a module is modified, it will no longer match the remote repository and linting tests of this module will fail.

!!! question "Exercise"

Modify the resources allocated to the `SEQTK_TRIM` process by changing the label 'process_low' to 'process_medium'. Check to see if your change has caused the linting test to fail.

First, modify the `SEQTK_TRIM` process my changing the label 'process_low' to 'process_medium'

```groovy title="modules/nf-core/seqtk/trim/main.nf" linenums="1"
process SEQTK_TRIM {
tag "$meta.id"
label 'process_medium'
```

Next, use the `nf-core lint` command to test your pipeline.

```console
╭─ [✗] 1 Module Test Failed ─────────────────────────────────────────────────────────────────────╮
│╷╷│
│ Module name│ File path│ Test message │
│╶─────────────┼────────────────────────────────────┼────────────────────────────────────────────│
│ fastp│ modules/nf-core/seqtk/trim/main.nf │ Local copy of module does not match remote │
│╵ ╵│
╰───────────────────────────────────────────────────────────────────────────────────────────╯
```

**One test is expected to fail.**

Changing a module does not mean you can't continue to use that module.

The `nf-core modules patch` command allows you keep using the nf-core component without needing to make it into a `local` module for linting tests to pass. Instead, the `nf-core modules patch` command creates a `diff` file that will keep track of the changes you made. If you subsequently update the module using the nf-core tooling, the `diff` file will be retained in the module directory. If any subsequent changes to the module conflict with your `diff` file, you will be prompted to resolve the conflicts.

```bash
nf-core modules patch
```

!!! question "Exercise"

    First, execute the `nf-core modules patch` and follow the prompts to patch the `seqtk/trim` module:

    ```bash
    ? Module name: seqtk/trim
    ```

    Second, view the log output to see what has changed:

    ```bash
    INFO Changes in module 'nf-core/seqtk/trim'
    INFO 'modules/nf-core/seqtk/trim/environment.yml' is unchanged
    INFO Changes in 'seqtk/trim/main.nf':

    --- modules/nf-core/seqtk/trim/main.nf
    +++ modules/nf-core/seqtk/trim/main.nf
    @@ -1,6 +1,6 @@
    process SEQTK_TRIM {
    tag "$meta.id"
    -label 'process_low'
    +label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?

    INFO 'modules/nf-core/seqtk/trim/meta.yml' is unchanged
    INFO 'modules/nf-core/seqtk/trim/tests/main.nf.test' is unchanged
    INFO 'modules/nf-core/seqtk/trim/tests/main.nf.test.snap' is unchanged
    INFO 'modules/nf-core/seqtk/trim/tests/tags.yml' is unchanged
    INFO Patch file of 'modules/nf-core/seqtk/trim' written to 'modules/nf-core/seqtk/trim/seqtk-trim.diff'
    ```

    Finally, use the nf-core lint command to see if your tests now pass:

    ```
    nf-core lint
    ```

    And check that your pipeline still runs successfully:

    ```bash
    nextflow run nf-core-myfirstpipeline -profile test,singularity --outdir results_patchedmodule
    ```

## Custom remote modules

As an individual or group, you may want to keep your own library of components.

The `nf-core modules` command comes with two flags for specifying a custom remote:

-   `--git-remote <git remote url>`: Specifies the repository from which the modules should be fetched as a git URL.
-   `--branch <branch name>`: Specifies the branch from which the modules should be fetched.

Note that a custom remote must follow a similar directory structure to that of `nf-core/modules` for the nf-core commands to work properly.

The directory where modules are installed will be prompted or obtained from `org_path` in the `.nf-core.yml` file, if it is available. If a module was located at `modules/my-folder/TOOL/SUBTOOL` your `.nf-core.yml` should have:

```console title=".nf-core.yml" linenums="1"
org_path: my-folder
```

The modules commands will, during initialization, try to pull changes from the remote repositories. If you want to disable this, for example, due to performance reasons, you can use the flag `--no-pull`. Commands will still need to clone repositories that have previously not been used.

!!! info "Private modules repositories"

    In order to browse private repositories you have to configure the [GitHub CLI auth](https://cli.github.com/manual/gh_auth_login) and provide your credentials with the command below.

    ```
    gh auth login
    ```

## Push your changes to GitHub

Now you have added a new custom module and patched a module you should commit your changes to GitHub.

You can check which branch you are on using the `git branch` command.

You can push your changes to the same `myFeature` branch you have been working on.

!!! question "Exercise"

    Push your changes to your GitHub repository.

    ```bash
    git add .
    git commit -m "Added CUSTOM_FASTQC and patched SEQTK_TRIM"
    ```

---

Congratulations! You have added a local module to your pipeline and patched an nf-core module!
