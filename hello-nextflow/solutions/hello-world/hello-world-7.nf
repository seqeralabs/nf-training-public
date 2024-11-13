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

    // convert the greeting to uppercase
    convertToUpper(sayHello.out)
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

/*
 * Use a text replace utility to convert the greeting to uppercase
 */
process convertToUpper {
    input:
    path input_file

    output:
    path "UPPER-${input_file}"

    script:
    """
    cat '${input_file}' | tr '[a-z]' '[A-Z]' > UPPER-${input_file}
    """
}
