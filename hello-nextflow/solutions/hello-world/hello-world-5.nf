#!/usr/bin/env nextflow
workflow {

    // create a channel for inputs
    greeting_ch = Channel.of('Hello world!')

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
    echo '${greeting}' > output.txt
    """
}
