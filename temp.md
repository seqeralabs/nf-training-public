From a technical standpoint, you can create a module simply by copying the process definition into its own file, and you can name that file anything you want.
However, the Nextflow community has adopted certain conventions for code organization, influenced in large part by the [nf-core](https://nf-co.re) project (which we'll cover later in this training series).

The convention for Nextflow modules is that the process definition should be written to a standalone file named `main.nf`, stored in a directory structure with three to four levels:

```console title="Directory structure"
modules
└── local
    └── (<toolkit>)
        └── <tool>
            └── main.nf
```

By convention, all modules are stored in a directory named `modules`.
Additionally, the convention distinguishes _local_ modules (which are part of your project) from _remote_ modules contained in remote repositories.

The next levels down are named after the toolkit (if there is one) then the tool itself.
If the process defined in the module invokes more than one tool, as the GATK_JOINTGENOTYPING does in our example workflow, the name of the module can be the name of the method, or something to that effect.

For example, the module we create for the `SAMTOOLS_INDEX` process will live under `modules/local/samtools/index/`.

```console title="Directory structure"
modules
└── local
    └── samtools
        └── index
            └── main.nf
```

!!!note

    We will cover remote modules later in this training, when we introduce the [nf-core library of modules](https://nf-co.re/modules/).
