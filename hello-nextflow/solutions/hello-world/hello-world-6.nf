#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */
params.greeting = "Bonjour le monde!"

workflow {

    // create a channel for inputs
    greeting_ch = Channel.of(params.greeting)

    // emit a greeting
    sayHello(greeting_ch)
}

/*
 * Use echo to print 'Hello World!' to standard out
 */
process sayHello {
    publishDir 'results', mode: 'copy'

    input:
    val greeting

    output:
    path "output.txt"

    script:
    """
    echo '${greeting}' > "output.txt"
    """
}
