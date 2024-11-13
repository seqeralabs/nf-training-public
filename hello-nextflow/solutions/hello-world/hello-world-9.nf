#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */
params.input_file = "data/greetings.csv"

workflow {

    // create a channel for inputs from a CSV file
    greeting_ch = Channel.fromPath(params.input_file).splitCsv().flatten()

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
    path "${greeting}-output.txt"

    script:
    """
    echo '${greeting}' > '${greeting}-output.txt'
    """
}

/*
 * Use a text replace utility to convert the greeting to uppercase
 */
process convertToUpper {
    publishDir 'results', mode: 'copy'

    input:
    path input_file

    output:
    path "UPPER-${input_file}"

    script:
    """
    cat '${input_file}' | tr '[a-z]' '[A-Z]' > UPPER-${input_file}
    """
}
