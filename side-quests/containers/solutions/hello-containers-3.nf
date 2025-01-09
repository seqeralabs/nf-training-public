#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */
params.input_file = "containers/data/greetings.csv"
// params.character can be any of 'beavis', 'cheese', 'cow', 'daemon', 'dragon', 'fox', 'ghostbusters', 'kitty',
// 'meow', 'miki', 'milk', 'octopus', 'pig', 'stegosaurus', 'stimpy', 'trex', 'turkey', 'turtle', 'tux'
params.character = "cow"

/*
 * Use echo to print 'Hello World!' to standard out
 */
process sayHello {

    publishDir 'containers/results', mode: 'copy'

    input:
        val greeting

    output:
        path "output-*.txt"

    script:
        // Replace the spaces in the greeting with hyphens for the output filename
        def safe_greeting = greeting.tokenize(' ').join('-')
        """
        echo '$greeting' > 'output-${safe_greeting}.txt'
        """
}

/*
 * Use a cow (or other character) to say some text
 */
process cowSay {

    publishDir 'containers/results', mode: 'copy'
    container 'community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65'

    input:
        path input_file

    output:
        path "cowsay-*"

    script:
    """
    cowsay -c "$params.character" -t "\$(cat $input_file)" > cowsay-${input_file}
    """
}

workflow {

    // create a channel for inputs from a CSV file
    input_ch = Channel.fromPath(params.input_file)
        .splitCsv()
        .flatten()

    sayHello(input_ch)

    // cowSay the text
    cowSay(sayHello.out)
}
