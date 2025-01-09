In Part 2 of this workshop, you will use the nf-core tooling to continue development of your pipeline and customize parts of the nf-core template.

By the end of this workshop you will be able to:

-   Add local modules
-   Patch nf-core modules
-   Customize linting tests
-   Sync TEMPLATE
-   Bump versions

# Customizing the template

## Adding a custom modules

nf-core offers a comprehensive set of modules that have been created and curated by the community. However, as a developer, you may be interested in bespoke pieces of software that are not apart of the nf-core repository or customizing a module that already exists.

Running `nf-core lint` after you have modified an nf-core module will cause it to throw an error.

```console
╭─ [✗] 1 Module Test Failed ────────────────────────────────────────────────────────────────╮
│              ╷                               ╷                                            │
│ Module name  │ File path                     │ Test message                               │
│╶─────────────┼───────────────────────────────┼────────────────────────────────────────────│
│ fastp        │ modules/nf-core/fastp/main.nf │ Local copy of module does not match remote │
│              ╵                               ╵                                            │
╰───────────────────────────────────────────────────────────────────────────────────────────╯
```

Changing a module does not mean you can't continue to use that module.

The `nf-core modules patch` command allows you keep using the nf-core component without needing to make it into a `local` module for tests to pass. Instead, `nf-core modules patch` command creates a `diff` file that will keep track of the changes you made. If you subsequently update the module using the nf-core tooling, the `diff` file will be retained. If any subsequent changes to the module conflict with your `diff` file, you will be prompted to resolve the conflicts.

```bash
nf-core modules patch
```

The prompt can be followed to patch the `fastp` module.

```bash
? Module name: fastp
```

A patch file is created in the fastp module directory

```bash
...
INFO     'modules/nf-core/fastp/tests/main.nf.test.snap' is unchanged
INFO     'modules/nf-core/fastp/tests/tags.yml' is unchanged
INFO     'modules/nf-core/fastp/tests/nextflow.config' is unchanged
INFO     'modules/nf-core/fastp/tests/main.nf.test' is unchanged
INFO     Patch file of 'modules/nf-core/fastp' written to 'modules/nf-core/fastp/fastp.diff'
```

!!! question "Exercise"

    Patch the `fastp` module to fix the linting error.

## Ignoring linting tests

The linting tests in the nf-core template are primarily designed for pipelines that are shared as a part of the nf-core project and you may want to ignore certain linting tests if they are not required.

The `.nf-core.yml` file can be modified to choose which linting tests you would like to skip.

For example, by default, there is a linting test that checks if the `CODE_OF_CONDUCT.md` matches the template. If the `CODE_OF_CONDUCT.md` has been modified the linting test will fail.

```console
╭─ [✗] 1 Pipeline Test Failed ────────────────────────────────────╮
│                                                                 │
│ files_unchanged: CODE_OF_CONDUCT.md does not match the template │
│                                                                 │
╰─────────────────────────────────────────────────────────────────╯
```

If you were to alter the `CODE_OF_CONDUCT.md` the `nf-core lint` command will suggest a command to fix this warning.

```console
Tip: Some of these linting errors can automatically be resolved with the following command:

    nf-core lint --fix files_unchanged
```

However, if you wish to remove or modify this file you would need to ignore this test. To do this, you would need to list the `CODE_OF_CONDUCT.md` as a `files_unchanged:` in the `.nf-core.yml` file.

```yml title=".nf-core.yml"
repository_type: pipeline
lint:
    files_unchanged:
        - CODE_OF_CONDUCT.md
```

If you run `nf-core lint` again, you would see that the test is now ignored and there are no more failed tests.

```console
╭─ [?] 1 Pipeline Test Ignored ────────────────────────────────────────╮
│                                                                      │
│ files_unchanged: File ignored due to lint config: CODE_OF_CONDUCT.md │
│                                                                      │
╰──────────────────────────────────────────────────────────────────────╯
```

!!! question "Exercise"

    Edit the `CODE_OF_CONDUCT.md` in your pipeline repository (e.g., add another bullet point). Use the `nf-core lint` command to see if it passes or fails. Add the `CODE_OF_CONDUCT.md` as a `files_unchanged:` in the `.nf-core.yml` file and lint your pipeline again to show that the test has been ignored.

A full list of checks, descriptions of how they work, and how they can be customized can be found on the [tools documentation website](https://nf-co.re/tools/docs/latest/).

!!! question "Bonus Exercise"

    Modify the `.nf-core.yml` file to prevent `pipeline_todos` from showing as warnings in your lint tests.

    ```yml title=".nf-core.yml"
    repository_type: pipeline
    lint:
        pipeline_todos: false
        files_unchanged:
            - CODE_OF_CONDUCT.md
    ```

## Custom remote modules

As an individual or group, you may want to keep your own library of modules and/or subworkflows.

The nf-core modules command comes with two flags for specifying a custom remote:

-   `--git-remote <git remote url>`: Specifies the repository from which the modules should be fetched as a git URL.
-   `--branch <branch name>`: Specifies the branch from which the modules should be fetched.

Note that a custom remote must follow a similar directory structure to that of `nf-core/modules` for the nf-core commands to work properly.

The directory where modules are installed will be prompted or obtained from `org_path` in the `.nf-core.yml` file, if it is available. If a module was located at `modules/my-folder/TOOL/SUBTOOL` your `.nf-core.yml` should have:

```console title=".nf-core.yml"
org_path: my-folder
```

The modules commands will, during initialization, try to pull changes from the remote repositories. If you want to disable this, for example, due to performance reasons, you can use the flag `--no-pull`. Commands will still need to clone repositories that have previously not been used.

!!! info "Private modules repositories"

    In order to browse private repositories you have to configure the [GitHub CLI auth](https://cli.github.com/manual/gh_auth_login) and provide your credentials with the command below.

    ```
    gh auth login
    ```

## `TEMPLATE` syncs

The template evolves as the ecosystem evolves.

To keep nf-core pipelines up to date with improvements in the main template, you can use a method of synchronization with the `TEMPLATE` branch.

To sync the template, you first need to commit and push your changes to GitHub. The `nf-core sync` command can then be used to update the `TEMPLATE` branch with the latest version of the nf-core template, so that these updates can be synchronized with the pipeline. It is run automatically for all pipelines whenever a new release of nf-core/tools (and the included template) is made.

```bash
nf-core sync
```

The tooling merges updates suggesting a git command

```bash
cd /workspace/gitpod/nf-develop/nf-core-myfirstpipeline
git merge TEMPLATE
```

!!! note

    For a newly created pipeline the `TEMPLATE` branch doesn't need to be synced.

### Changes to the template structure

Occasionally, the structure of the nf-core pipeline template is updated during a new release of the nf-core tooling. Most of the time these changes are minor. However, sometimes, larger structural changes are adopted to align with changes in the wider ecosystem.

For example, as of nf-core tools 2.13, the groovy code that once lived in the `lib` folder has been moved to `subworkflows/`. Moving this code has made it easier to find, modify, and test the code. Importantly, it's modular nature is paving the way for a more flexible template in the future.

!!! note

    The `TEMPLATE` branch is essential for adopting these changes.

## Update minimum Nextflow version

The template also includes a minimum Nextflow version that is required for the pipeline to run. You can also change the required version of Nextflow using the `nf-core bump-version` command. These versions can also be used during GitHub Actions to test your pipeline with upper and lower version limits.

```bash
nf-core bump-version 23.04.0 --nextflow
```

!!! question "Exercise"

    Update the minimum version of Nextflow required to run your pipeline to `23.04.0` and push the changes to GitHub.

!!! note "Tagged versions"

    Creating a tagged version release allows you to execute specific versions of your pipeline using the revision flag.

## Bump your pipeline version

Having a universal way of versioning the development projects is the best way to track what is going on with the software as new features are added. This problem can be solved by following semantic versioning rules: `[major].[minor].[patch]`

For example, starting with a release version `1.4.3`, bumping the version to:

-   `1.4.4` would be a patch release for minor things such as fixing bugs.
-   `1.5` would be a minor release, for example adding some new features.
-   `2.0` would correspond to the major release where results would no longer be backward compatible.

The pipeline version number is mentioned in a lot of different places in nf-core pipelines. The `nf-core bump-version` command updates the version for you automatically, so that you don't accidentally miss any. It can be used for each pipeline release, and again for the next development version after release.

```bash
nf-core bump-version 1.0
```

After you have updated the version of your pipeline, your changes can be pushed to GitHub.

!!! question "Exercise"

    Bump your pipeline version to `1.0` using the `nf-core bump-version` command.

### Push your changes to GitHub

When you are satisfied with your improvements you can `add`, `commit`, and `push` your changes to GitHub.

You can check which branch you are on using the `git branch` command.

As your current branch `myFeature` has no upstream branch you will need to set the remote as upstream the first time you push your changes.

!!! question "Exercise"

    Push your changes to your GitHub repository.

    ```bash
    git add .
    git commit -m "Added fastp to pipeline"
    git push --set-upstream origin myFeature
    ```

!!! note "Branch origin"

    To automatically add an origin for branches without a tracking upstream, see `push.autoSetupRemote` in `git help config`.
