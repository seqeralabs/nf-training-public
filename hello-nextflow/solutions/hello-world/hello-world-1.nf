#!/usr/bin/env nextflow
workflow {
    sayHello()
}


process sayHello {
    output:
    stdout

    script:
    """
    echo 'Hello World!'
    """
}
