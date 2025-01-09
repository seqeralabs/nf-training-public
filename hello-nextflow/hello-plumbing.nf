#!/usr/bin/env nextflow

/*
 * Use echo to print 'Hello World!' to a file
 */
process sayHello {

    publishDir 'results', mode: 'copy'

    input:
        val greeting

    output:
        path "${greeting}-output.txt"

    script:
    """
    echo '$greeting' > '$greeting-output.txt'
    """
}

/*
 * Pipeline parameters
 */
params.greeting = 'data/greetings.csv'

workflow {

    // create a channel for inputs from a CSV file
    greeting_ch = Channel.fromPath(params.greeting)
                     .splitCsv()
                     .flatten()

    // emit a greeting
    sayHello(greeting_ch)
}
