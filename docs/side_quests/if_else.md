# Part 2: If - Else

[TODO]

---

## 1. Make the cow quote famous scientists

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

### 1.1. Modify the `hello-containers.nf` script to use a getQuote process

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

### 1.2. Modify your Nextflow pipeline to allow it to execute in `quote` and `sayHello` modes.

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
