#!/usr/bin/env nextflow
workflow {

    // emit a greeting
    sayHello()
}


/*
 * Use echo to print 'Hello World!' to standard out
 */
process sayHello {
    publishDir 'results', mode: 'copy'

    output:
    path 'output.txt'

    script:
    """
    echo 'Hello World!' > output.txt
    """
}
