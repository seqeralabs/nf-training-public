# Metadata Propagation

A central challenge in a lot of batch-style computation is how to ensure the metadata describing a file remains with the file. Two good rules for handling metadata in Nextflow are:

-   Metadata should be explicit - be extremely wary of metadata encoded in filenames
-   Metadata should travel through channels with the data in a tuple element.

## Metadata Import

Ideally, you have sample information stored in a simple and structured samplesheet. These are often files in CSV/TSV format or similar. I'd like to start with a worst-case scenario where you've been handed a bag of files that you need to make sense of. We'll use this example to introduce some helpful Groovy syntactic sugar and features that will be helpful in other Nextflow contexts.

Given a bag of fastq reads:

```bash
cd metadata
tree data/reads
```

```console title="Output"
data/reads/
|-- treatmentA
|   |-- sampleA_rep1_normal_R1.fastq.gz
|   |-- sampleA_rep1_normal_R2.fastq.gz
|   |-- sampleA_rep1_tumor_R1.fastq.gz
|   |-- sampleA_rep1_tumor_R2.fastq.gz
|   |-- sampleA_rep2_normal_R1.fastq.gz
|   |-- sampleA_rep2_normal_R2.fastq.gz
|   |-- sampleA_rep2_tumor_R1.fastq.gz
|   |-- sampleA_rep2_tumor_R2.fastq.gz
|   |-- sampleB_rep1_normal_R1.fastq.gz
|   |-- sampleB_rep1_normal_R2.fastq.gz
|   |-- sampleB_rep1_tumor_R1.fastq.gz
|   |-- sampleB_rep1_tumor_R2.fastq.gz
|   |-- sampleC_rep1_normal_R1.fastq.gz
|   |-- sampleC_rep1_normal_R2.fastq.gz
|   |-- sampleC_rep1_tumor_R1.fastq.gz
|   `-- sampleC_rep1_tumor_R2.fastq.gz
`-- treatmentB
    |-- sampleA_rep1_normal_R1.fastq.gz
    |-- sampleA_rep1_normal_R2.fastq.gz
    |-- sampleA_rep1_tumor_R1.fastq.gz
    `-- sampleA_rep1_tumor_R2.fastq.gz
```

!!! warning

    Whomever has handed us these files has encoded metadata in both the filename, but also the name of the parent directories `treatmentA` and `treatmentB`.

### First Pass

A first pass attempt at pulling these files into Nextflow might use the `fromFilePairs` method:

```groovy linenums="1"
workflow {
    Channel.fromFilePairs("data/reads/*/*_R{1,2}.fastq.gz")
    | view
}
```

Nextflow will pull out the first part of the fastq filename and returned us a channel of tuple elements where the first element is the filename-derived ID and the second element is a list of two fastq files.

The id is stored as a simple string. We'd like to move to using a map of key-value pairs because we have more than one piece of metadata to track. In this example, we have sample, replicate, tumor/normal, and treatment. We could add extra elements to the tuple, but this changes the 'cardinality' of the elements in the channel and adding extra elements would require updating all downstream processes. A map is a single object and is passed through Nextflow channels as one value, so adding extra metadata fields will not require us to change the cardinality of the downstream processes.

There are a couple of different ways we can pull out the metadata

We can use the `tokenize` method to split our id. To sanity-check, I just pipe the result directly into the `view` operator.

```groovy linenums="1"
workflow {
    Channel.fromFilePairs("data/reads/*/*_R{1,2}.fastq.gz")
    | map { id, reads ->
        tokens = id.tokenize("_")
    }
    | view
}
```

If we are confident about the stability of the naming scheme, we can destructure the list returned by `tokenize` and assign them to variables directly:

```groovy linenums="1"
map { id, reads ->
    (sample, replicate, type) = id.tokenize("_")
    meta = [sample:sample, replicate:replicate, type:type]
    [meta, reads]
}
```

!!! note "Destructuring requires parentheses"

    Make sure that you're using a tuple with parentheses e.g. `(one, two)` rather than a List e.g. `[one, two]`

Another option is to use the [`transpose`](<https://docs.groovy-lang.org/latest/html/api/groovy/util/GroovyCollections.html#transpose(java.util.List)>) method with the [`collectEntries()`](<https://docs.groovy-lang.org/latest/html/api/org/codehaus/groovy/runtime/DefaultGroovyMethods.html#collectEntries(E[])>) to produce the same map. I'd warn that this method is bordering on a little 'too clever' and is more difficult to read. It also assumes that the order of the filename-encoded metadata is consistent.

```groovy linenums="1"
map { id, reads ->
    meta = [['sample', 'replicate', 'type'], id.tokenize("_")]
        .transpose()
        .collectEntries()
    [meta, reads]
}
```

If we move back to the previous method, but decided that the 'rep' prefix on the replicate should be removed, we can use regular expressions to simply "subtract" pieces of a string. Here we remove a 'rep' prefix from the `replicate` variable if the prefix is present:

```groovy linenums="1"
map { id, reads ->
    (sample, replicate, type) = id.tokenize("_")
    replicate -= ~/^rep/
    meta = [sample:sample, replicate:replicate, type:type]
    [meta, reads]
}
```

!!! tip "Trim strings"

    Groovy has a lot of very helpful syntactic sugar for string manipulation. You can trim parts of a string by simply subtracting another string:

    ```groovy linenums="1"
    demo = "one two three"
    assertEquals(demo - "two ", "one three")
    ```

    ... or by subtracting a regular expression:

    ```groovy linenums="1"
    demo = "one two three"
    assertEquals(demo - ~/t.o ?/, "one three")
    ```

    To quickly sanity-check a groovy expression, try the [Groovy web console](https://groovyconsole.appspot.com/)

We are almost there, but we still don't have the "treatment" metadata captured in our meta map. The treatment is encoded in this example in the name of the parent directory relative to the reads. Inside the map object, the reads are a list of two UnixPath objects. These objects implement the [`java.nio.Path`](https://docs.oracle.com/javase/7/docs/api/java/nio/file/Path.html) interface, which provides us many useful methods, including `getParent()`.

We can call the `getParent()` method on each of the paths like so:

```groovy linenums="1"
map { id, reads ->
    reads.collect { it.getParent() }
}
```

If we want to call a set method on every item in a Collection, Groovy provides this convenient "spread dot" notation:

```groovy linenums="1"
map { id, reads ->
    reads*.getParent()
}
```

This returns another Path object, but we only want the name of the last directory, so we need to call `.getName()` method on each of these Paths. We can use the spread-dot notation again:

```groovy linenums="1"
map { id, reads ->
    reads*.getParent()*.getName()
}
```

The last piece of Groovy sugar is to note that methods with `get` and `set` prefixes can be called with a property-style notation, converting `getParent()` to `parent` and `getName()` to `name`:

```groovy linenums="1"
map { id, reads ->
    reads*.parent*.name
}
```

If we wanted to remove the "treatment" prefix, we can combine this new notation with the "minus" method which we used earlier in the aliased `-` form.

```groovy linenums="1"
map { id, reads ->
    reads*.parent*.name*.minus(~/treatment/)
}
```

In this particular example, we know ahead of time that the treatments must be the same because of the way the `fromFilePairs` method gathers pairs, but we'll continue for the sake of the demonstration. Our final `map` closure might look like:

```groovy linenums="1"
workflow {
    Channel.fromFilePairs("data/reads/*/*_R{1,2}.fastq.gz")
    | map { id, reads ->
        (sample, replicate, type) = id.tokenize("_")
        (treatmentFwd, treatmentRev) = reads*.parent*.name*.minus(~/treatment/)
        meta = [
            sample:sample,
            replicate:replicate,
            type:type,
            treatmentFwd:treatmentFwd,
            treatmentRev:treatmentRev,
        ]
        [meta, reads]
    }
    | view
}
```

This metadata map can be passed through the workflow with the reads and used to split, join and recombine the data. The resulting channel would be suitable for any Nextflow process with inputs of the form

```groovy linenums="1"
process ExampleProcess {
    input:
    tuple val(meta), path(reads)

    // ...
```

This channel "shape" or cardinality is extremely common in nf-core modules and subworkflows and is critical to enabling reusability of these modules.
