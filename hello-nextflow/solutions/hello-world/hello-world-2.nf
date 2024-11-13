#!/usr/bin/env nextflow
workflow {

    // emit a greeting
    sayHello()
}


/*
 * Use echo to print 'Hello World!' to standard out
 */
process sayHello {
    output:
    stdout

    script:
    """
    echo 'Hello World!'
    """
}
