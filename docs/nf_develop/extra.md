In Part 2 of this workshop, you will use the nf-core tooling to continue development of your pipeline and customize parts of the nf-core template.

By the end of this workshop you will be able to:

-   Add local modules
-   Patch nf-core modules
-   Customize linting tests
-   Sync TEMPLATE
-   Bump versions

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
