---
description: Material de treinamento básico do Nextflow
---

# Processos

No Nextflow, um processo (`process`) é a primitiva de computação básica para executar funções estrangeiras (ou seja, scripts personalizados ou ferramentas).

A definição do processo começa com a palavra-chave `process`, seguida pelo nome do processo e, finalmente, o corpo do processo delimitado por chaves.

O nome do processo (`process`) é comumente escrito em letras maiúsculas por convenção.

Um processo básico, usando apenas o bloco de definição `script`, se parece com o seguinte:

```groovy linenums="1"
process DIGAOLA {
    script:
    """
    echo 'Olá mundo!'
    """
}
```

Em exemplos mais complexos, o corpo do processo pode conter até **cinco** blocos de definição:

1. **Diretivas** são declarações iniciais que definem configurações opcionais
2. **Input** (Bloco de entrada) define o(s) canal(is) de entrada esperado(s)
3. **Output** (Bloco de saída) define o(s) canal(is) de saída esperado(s)
4. **When** é uma declaração de cláusula opcional para permitir processos condicionais
5. **Script** é uma string que define o comando a ser executado pela tarefa do processo

A sintaxe completa do processo é definida da seguinte forma:

!!! info ""

    Clique no ícone :material-plus-circle: no código para ver explicações.

```groovy linenums="1"
process < nome > {
    [ diretivas ] // (1)!

    input: // (2)!
    < entradas do processo >

    output: // (3)!
    < saídas do processo >

    when: // (4)!
    < condição >

    [script|shell|exec]: // (5)!
    """
    < script do usuário a ser executado >
    """
}
```

1. Zero, uma ou mais diretivas de processo
2. Zero, uma ou mais entradas para o processo
3. Zero, uma ou mais saídas para o processo
4. Uma condicional booleana opcional para acionar a execução do processo
5. O comando a ser executado

## Script

O bloco `script` é uma string que define o comando a ser executado pelo processo.

Um processo pode executar apenas um bloco `script`. Deve ser a última instrução quando o processo contém declarações de entrada e saída.

O bloco `script` pode ser uma string de uma ou várias linhas. A de várias linhas simplifica a escrita de scripts não triviais compostos por vários comandos abrangendo várias linhas. Por exemplo:

```groovy linenums="1"
process EXEMPLO {
    script:
    """
    echo 'Olá mundo!\nHola mundo!\nCiao mondo!\nHallo Welt!' > arquivo
    cat arquivo | head -n 1 | head -c 5 > pedaco_1.txt
    gzip -c pedaco_1.txt > pedacos.gz
    """
}

workflow {
    EXEMPLO()
}
```

Por padrão, o comando do processo é interpretado como um script **Bash**. No entanto, qualquer outra linguagem de script pode ser usada simplesmente iniciando o script com a declaração [Shebang](<https://en.wikipedia.org/wiki/Shebang_(Unix)>) adequada. Por exemplo:

```groovy linenums="1"
process CODIGOPYTHON {
    script:
    """
    #!/usr/bin/env python

    x = 'Olá'
    y = 'mundo!'
    print ("%s - %s" % (x, y))
    """
}

workflow {
    CODIGOPYTHON()
}
```

!!! tip

    Várias linguagens de programação podem ser usadas no mesmo script de fluxo de trabalho. No entanto, para grandes blocos de código, é melhor salvá-los em arquivos separados e invocá-los a partir do script do processo. Pode-se armazenar os scripts específicos na pasta `./bin/`.

### Parâmetros do script

Parâmetros de script (`params`) podem ser definidos dinamicamente usando valores variáveis. Por exemplo:

```groovy linenums="1"
params.dado = 'Mundo'

process FOO {
    script:
    """
    echo Olá $params.dado
    """
}

workflow {
    FOO()
}
```

!!! info

    Um script de processo pode conter qualquer formato de string suportado pela linguagem de programação Groovy. Isso nos permite usar a interpolação de strings como no script acima ou strings multilinha. Consulte [Interpolação de string](../groovy/#interpolacao-de-strings) para obter mais informações.

!!! warning

    Como o Nextflow usa a mesma sintaxe Bash para substituições de variáveis em strings, as variáveis de ambiente Bash precisam ser escapadas usando o caractere `\`. A versão escapada será resolvida posteriormente, retornando o diretório da tarefa (por exemplo, work/7f/f285b80022d9f61e82cd7f90436aa4/), enquanto `$PWD` mostraria o diretório onde você está executando o Nextflow.

```groovy linenums="1"
process FOO {
    script:
    """
    echo "O diretório atual é \$PWD"
    """
}

workflow {
    FOO()
}
```

Pode ser complicado escrever um script que usa muitas variáveis Bash. Uma alternativa possível é usar uma string de script delimitada por aspas simples

```groovy linenums="1"
process BAR {
    script:
    '''
    echo "The current directory is $PWD"
    '''
}

workflow {
    BAR()
}
```

No entanto, isso bloqueia o uso de variáveis Nextflow no script de comando.

Outra alternativa é usar uma instrução `shell` em vez de `script` e usar uma sintaxe diferente para variáveis do Nextflow, por exemplo, `!{..}`. Isso permite o uso das variáveis Nextflow e Bash no mesmo script.

```groovy linenums="1"
params.dado = 'le monde'

process BAZ {
    shell:
    '''
    X='Bonjour'
    echo $X !{params.dado}
    '''
}

workflow {
    BAZ()
}
```

### Scripts condicionais

O script do processo também pode ser definido de maneira completamente dinâmica usando uma instrução `if` ou qualquer outra expressão para avaliar um valor de string. Por exemplo:

```groovy linenums="1"
params.compressor = 'gzip'
params.arquivo_a_comprimir = "$projectDir/data/ggal/transcriptome.fa"

process FOO {
    input:
    path arquivo

    script:
    if (params.compressor == 'gzip')
        """
        gzip -c $arquivo > ${arquivo}.gz
        """
    else if (params.compressor == 'bzip2')
        """
        bzip2 -c $arquivo > ${arquivo}.bz2
        """
    else
        throw new IllegalArgumentException("Compressor $params.compressor desconhecido")
}

workflow {
    FOO(params.arquivo_a_comprimir)
}
```

## Canais de entradas

As instâncias dos processos (tarefas) Nextflow são isoladas umas das outras, mas podem se comunicar entre si enviando valores por meio de canais.

As entradas determinam implicitamente as dependências e a execução paralela do processo. A execução do processo é disparada cada vez que dados _novos_ estão prontos para serem consumidos do canal de entrada:

<figure class="excalidraw">
--8<-- "docs/basic_training/img/channel-process.excalidraw.pt.svg"
</figure>

O bloco `input` define os nomes e qualificadores das variáveis que se referem aos elementos do canal direcionados ao processo. Você só pode definir um bloco `input` por vez e deve conter uma ou mais declarações de entrada.

O bloco `input` segue a sintaxe mostrada abaixo:

```groovy linenums="1"
input:
<qualificador da variável de entrada> <nome da variável de entrada>
```

### Valores de entrada

O qualificador `val` permite receber dados de qualquer tipo como entrada. Ele pode ser acessado no script do processo usando o nome de entrada especificado, conforme mostrado no exemplo a seguir:

```groovy linenums="1"
num = Channel.of(1, 2, 3)

process EXEMPLOBASICO {
    debug true

    input:
    val x

    script:
    """
    echo tarefa $x do processo
    """
}

workflow {
    minha_execucacao = EXEMPLOBASICO(num)
}
```

No exemplo acima, o processo é executado três vezes, cada vez que um valor é recebido do canal `num` e usado para processar o script. Assim, resulta em uma saída semelhante à mostrada abaixo:

```console
tarefa 3 do processo
tarefa 1 do processo
tarefa 2 do processo
```

!!! warning

    O canal garante que os itens sejam entregues na mesma ordem em que foram enviados - mas - como o processo é executado de forma paralela, não há garantia de que sejam processados na mesma ordem em que foram recebidos.

### Arquivo e caminhos de entrada

O qualificador `path` permite a manipulação de arquivos no contexto de execução do processo. Isso significa que o Nextflow irá mover os arquivos necessários para o diretório de execução do processo e estes poderão ser acessados no script usando o nome especificado na declaração de entrada.

```groovy linenums="1"
leituras = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path 'amostra.fastq'

    script:
    """
    ls amostra.fastq
    """
}

workflow {
    resultado = FOO(leituras)
}
```

O nome do arquivo de entrada também pode ser definido usando uma referência de variável conforme mostrado abaixo:

```groovy linenums="1"
leituras = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path amostra

    script:
    """
    ls $amostra
    """
}

workflow {
    resultado = FOO(leituras)
}
```

A mesma sintaxe também é capaz de lidar com mais de um arquivo de entrada na mesma execução e requer apenas a alteração da composição do canal.

```groovy linenums="1"
leituras = Channel.fromPath('data/ggal/*.fq')

process FOO {
    debug true

    input:
    path amostra

    script:
    """
    ls -lh $amostra
    """
}

workflow {
    FOO(leituras.collect())
}
```

!!! warning

    No passado, o qualificador `file` era usado para arquivos, mas o qualificador `path` deve ser preferido ao `file` para lidar com arquivos de entrada de processo ao usar o Nextflow 19.10.0 ou posterior. Quando um processo declara um arquivo de entrada, os elementos de canal correspondentes devem ser objetos **file** criados com a função auxiliar de arquivo das fábricas de canal específicas de arquivo (por exemplo, `Channel.fromPath` ou `Channel.fromFilePairs`).

!!! exercise

    Escreva um script que crie um canal contendo todos as leituras correspondentes ao padrão `data/ggal/*_1.fq` seguido por um processo que os concatene em um único arquivo e imprima as primeiras 10 linhas.


    ??? solution

        ```groovy linenums="1"
        params.leituras = "$projectDir/data/ggal/*_1.fq"

        Channel
            .fromPath(params.leituras)
            .set { canal_leituras }

        process CONCATENE {
            tag "Concatene todos os arquivos"

            input:
            path '*'

            output:
            path 'top_10_linhas'

            script:
            """
            cat * > concatenado.txt
            head -n 10 concatenado.txt > top_10_linhas
            """
        }

        workflow {
            canal_concatenado = CONCATENE(canal_leituras.collect())
            canal_concatenado.view()
        }
        ```

### Combinando canais de entrada

Uma característica fundamental dos processos é a capacidade de lidar com entradas de vários canais. No entanto, é importante entender como o conteúdo do canal e sua semântica afetam a execução de um processo.

Considere o seguinte exemplo:

```groovy linenums="1"
canal1 = Channel.of(1, 2, 3)
canal2 = Channel.of('a', 'b', 'c')

process FOO {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x e $y
    """
}

workflow {
    FOO(canal1, canal2)
}
```

Ambos os canais emitem três valores, portanto o processo é executado três vezes, cada vez com um par diferente:

-   `(1, a)`
-   `(2, b)`
-   `(3, c)`

O que está acontecendo é que o processo espera até que haja uma configuração de entrada completa, ou seja, recebe um valor de entrada de todos os canais declarados como entrada.

Quando essa condição é verificada, ele consome os valores de entrada provenientes dos respectivos canais, gera uma execução de tarefa e repete a mesma lógica até que um ou mais canais não tenham mais conteúdo.

Isso significa que os valores do canal são consumidos serialmente um após o outro e o primeiro canal vazio faz com que a execução do processo pare, mesmo que existam outros valores em outros canais.

**Então, o que acontece quando os canais não têm a mesma cardinalidade (isto é, eles emitem um número diferente de elementos)?**

Por exemplo:

```groovy linenums="1"
entrada1 = Channel.of(1, 2)
entrada2 = Channel.of('a', 'b', 'c', 'd')

process FOO {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x e $y
    """
}

workflow {
    FOO(entrada1, entrada2)
}
```

No exemplo acima, o processo só é executado duas vezes porque o processo para quando um canal não tem mais dados para serem processados.

No entanto, o que acontece se você substituir o valor `x` por um canal de valor?

Compare o exemplo anterior com o seguinte:

```groovy linenums="1"
entrada1 = Channel.value(1)
entrada2 = Channel.of('a', 'b', 'c')

process BAR {
    debug true

    input:
    val x
    val y

    script:
    """
    echo $x e $y
    """
}

workflow {
    BAR(entrada1, entrada2)
}
```

```console title="Script output"
1 e b
1 e a
1 e c
```

Isso ocorre porque os canais de valor podem ser consumidos várias vezes e não afetam o término do processo.

!!! exercise

    Escreva um processo que é executado para cada arquivo de leitura correspondente ao padrão `data/ggal/*_1.fq` e use o mesmo `data/ggal/transcriptome.fa` em cada execução.

    ??? solution

        ```groovy linenums="1"
        params.leituras = "$projectDir/data/ggal/*_1.fq"
        params.arquivo_transcriptoma = "$projectDir/data/ggal/transcriptome.fa"

        Channel
            .fromPath(params.leituras)
            .set { canal_leituras }

        process COMANDO {
            tag "Execute_comando"

            input:
            path leituras
            path transcriptoma

            output:
            path resultado

            script:
            """
            echo seu_comando $leituras $transcriptoma > resultado
            """
        }

        workflow {
            canal_concatenado = COMANDO(canal_leituras, params.arquivo_transcriptoma)
            canal_concatenado.view()
        }
        ```

### Repetidores de entradas

O qualificador `each` permite que você repita a execução de um processo para cada item em uma coleção toda vez que novos dados são recebidos. Por exemplo:

```groovy linenums="1"
sequencias = Channel.fromPath('data/prots/*.tfa')
metodos = ['regular', 'espresso', 'psicoffee']

process ALINHESEQUENCIAS {
    debug true

    input:
    path sequencia
    each modo

    script:
    """
    echo t_coffee -in $sequencia -mode $modo
    """
}

workflow {
    ALINHESEQUENCIAS(sequencias, metodos)
}
```

No exemplo acima, toda vez que um arquivo de sequências é recebido como entrada pelo processo, ele executa três tarefas, cada uma executando um método de alinhamento diferente definido como uma variável `modo`. Isso é útil quando você precisa repetir a mesma tarefa para um determinado conjunto de parâmetros.

!!! exercise

    Estenda o exemplo anterior para que uma tarefa seja executada para cada arquivo de leitura correspondente ao padrão `data/ggal/*_1.fq` e repita a mesma tarefa com `salmon` e `kallisto`.

    ??? solution

        ```groovy linenums="1"
        params.leituras = "$projectDir/data/ggal/*_1.fq"
        params.arquivo_transcriptoma = "$projectDir/data/ggal/transcriptome.fa"
        metodos= ['salmon', 'kallisto']

        Channel
            .fromPath(params.leituras)
            .set { canal_leituras }

        process COMANDO {
            tag "Execute_comando"

            input:
            path leituras
            path transcriptoma
            each modo

            output:
            path resultado

            script:
            """
            echo $modo $leituras $transcriptoma > resultado
            """
        }

        workflow {
            canal_concatenado = COMANDO(canal_leituras, params.arquivo_transcriptoma, metodos)
            canal_concatenado.view { "Para executar : ${it.text}" }
        }
        ```

## Canais de saída

O bloco `output` define os canais usados pelo processo para enviar os resultados produzidos.

Apenas um bloco de saída, que pode conter uma ou mais declarações de saída, pode ser definido. O bloco de saída segue a sintaxe mostrada abaixo:

```groovy linenums="1"
output:
<qualificador da variável de saída> <nome da variável de saída>, emit: <nome do canal de saída>
```

### Valores de saída

O qualificador `val` especifica um valor definido no contexto do script. Os valores são frequentemente definidos nos blocos de _input_ e/ou _output_, conforme mostrado no exemplo a seguir:

```groovy linenums="1"
metodos = ['prot', 'dna', 'rna']

process FOO {
    input:
    val x

    output:
    val x

    script:
    """
    echo $x > arquivo
    """
}

workflow {
    canal_de_recebimento = FOO(Channel.of(metodos))
    canal_de_recebimento.view { "Recebido: $it" }
}
```

### Caminhos e arquivos de saída

O qualificador `path` especifica um ou mais arquivos produzidos pelo processo no canal especificado como uma saída.

```groovy linenums="1"
process NUMALEATORIO {
    output:
    path 'resultado.txt'

    script:
    """
    echo \$RANDOM > resultado.txt
    """
}

workflow {
    canal_de_recebimento = NUMALEATORIO()
    canal_de_recebimento.view { "Recebido: " + it.text }
}
```

No exemplo acima, o processo `NUMALEATORIO` cria um arquivo chamado `resultado.txt` contendo um número aleatório.

Como um parâmetro de arquivo usando o mesmo nome é declarado no bloco de saída, o arquivo é enviado pelo canal `canal_de_recebimento` quando a tarefa é concluída. Um processo posterior declarando o mesmo canal como _input_ será capaz de recebê-lo.

### Múltiplos arquivos de saída

Quando um nome de arquivo de saída contém um caractere curinga (`*` ou `?`), ele é interpretado como um [glob](http://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob) de correspondência para um caminho. Isso nos permite _capturar_ vários arquivos em um objeto de lista e exibi-los como uma única emissão. Por exemplo:

```groovy linenums="1"
process SEPARARLETRAS {
    output:
    path 'pedaco_*'

    script:
    """
    printf 'Hola' | split -b 1 - pedaco_
    """
}

workflow {
    letters = SEPARARLETRAS()
    letters
        .flatMap()
        .view { "Arquivo: ${it.name} => ${it.text}" }
}
```

Imprime o seguinte:

```console
Arquivo: pedaco_aa => H
Arquivo: pedaco_ab => o
Arquivo: pedaco_ac => l
Arquivo: pedaco_ad => a
```

Algumas advertências sobre o comportamento de padrões de glob:

-   Os arquivos de entrada não estão incluídos na lista de possíveis correspondências
-   O padrão glob corresponde tanto a arquivos quanto caminhos de diretório
-   Quando um padrão de duas estrelas `**` é usado para acessar os diretórios, apenas os caminhos de arquivo são correspondidos, ou seja, os diretórios não são incluídos na lista de resultados.

!!! exercise

    Remova o operador `flatMap` e veja a mudança de saída. A documentação para o operador `flatMap` está disponível [nesse link](https://www.nextflow.io/docs/latest/operator.html#flatmap).

    ??? Solution

        ```groovy
        File: [pedaco_aa, pedaco_ab, pedaco_ac, pedaco_ad] => [H, o, l, a]
        ```

### Nomes dinâmicos de arquivos de saída

Quando um nome de arquivo de saída precisa ser expresso dinamicamente, é possível defini-lo usando uma string dinâmica que faz referência a valores definidos no bloco de declaração de entrada ou no contexto global do script. Por exemplo:

```groovy linenums="1"
especies = ['gato', 'cachorro', 'preguiça']
sequencias = ['AGATAG', 'ATGCTCT', 'ATCCCAA']

Channel
    .fromList(especies)
    .set { canal_especies }

process ALINHAR {
    input:
    val x
    val sequencia

    output:
    path "${x}.aln"

    script:
    """
    echo alinhar -in $sequencia > ${x}.aln
    """
}

workflow {
    genomas = ALINHAR(canal_especies, sequencias)
    genomas.view()
}
```

No exemplo acima, cada vez que o processo é executado, é gerado um arquivo de alinhamento cujo nome depende do valor da entrada `x`.

### Entradas e saídas compostas

Até agora, vimos como declarar vários canais de entrada e saída que podem lidar com um valor por vez. No entanto, o Nextflow também pode lidar com tuplas de valores.

As declarações de entrada e saída para tuplas devem ser declaradas com um qualificador `tuple` seguido pela definição de cada elemento na tupla.

```groovy linenums="1"
canal_leituras = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

process FOO {
    input:
    tuple val(id_amostra), path(arquivos_amostra)

    output:
    tuple val(id_amostra), path('sample.bam')

    script:
    """
    echo seu_comando_aqui --leituras $arquivos_amostra > sample.bam
    """
}

workflow {
    canal_bam = FOO(canal_leituras)
    canal_bam.view()
}
```

!!! info

    Nas versões anteriores do Nextflow `tuple` era chamado `set`, mas era usado da mesma forma com a mesma semântica.

!!! exercise

    Modifique o script do exercício anterior para que o arquivo _bam_ seja nomeado com o `id_amostra` fornecido.

    ??? solution

        ```groovy linenums="1"
        canal_leituras = Channel.fromFilePairs('data/ggal/*_{1,2}.fq')

        process FOO {
            input:
            tuple val(id_amostra), path(arquivos_amostra)

            output:
            tuple val(id_amostra), path("${id_amostra}.bam")

            script:
            """
            echo seu_comando_aqui --leituras $arquivos_amostra > ${id_amostra}.bam
            """
        }

        workflow {
            canal_bam = FOO(canal_leituras)
            canal_bam.view()
        }
        ```

## When

A declaração `when` permite que você defina uma condição que deve ser verificada para executar o processo. Pode ser qualquer expressão que avalie um valor booleano.

É útil habilitar/desabilitar a execução do processo dependendo do estado de várias entradas e parâmetros. Por exemplo:

```groovy linenums="1"
params.tipo_banco = 'nr'
params.prot = 'data/prots/*.tfa'
proteinas = Channel.fromPath(params.prot)

process ENCONTRAR {
    debug true

    input:
    path fasta
    val tipo

    when:
    fasta.name =~ /^BB11.*/ && tipo == 'nr'

    script:
    """
    echo blastp -checar $fasta -tipo_banco nr
    """
}

workflow {
    resultado = ENCONTRAR(proteinas, params.tipo_banco)
}
```

## Diretivas

As declarações de diretiva permitem a definição de configurações opcionais que afetam a execução do processo atual sem afetar a _semântica_ da própria tarefa.

Elas devem ser inseridas no topo do corpo do processo, antes de quaisquer outros blocos de declaração (ou seja, `input`, `output`, etc.).

Diretivas são comumente usadas para definir a quantidade de recursos computacionais a serem usados ou outras meta diretivas que permitem a definição de configuração extra de informações de log. Por exemplo:

```groovy linenums="1"
process FOO {
    cpus 2
    memory 1.GB
    container 'nome/imagem'

    script:
    """
    echo seu_comando --isso --aquilo
    """
}
```

!!! info ""

    :material-lightbulb: A lista completa de diretivas está disponível [aqui](https://www.nextflow.io/docs/latest/process.html#directives).

| Nome                                                                | Descrição                                                                                                                                                            |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`cpus`](https://www.nextflow.io/docs/latest/process.html#cpus)     | Permite definir o número de CPUs (lógicas) necessárias para a tarefa do processo.                                                                                    |
| [`time`](https://www.nextflow.io/docs/latest/process.html#time)     | Permite definir por quanto tempo a tarefa pode ser executado (por exemplo, tempo _1h_: 1 hora, _1s_ 1 segundo, _1m_ 1 minuto, _1d_ 1 dia).                           |
| [`memory`](https://www.nextflow.io/docs/latest/process.html#memory) | Permite definir quanta memória a tarefa pode usar (por exemplo, _2 GB_ é 2 GB). Também pode usar B, KB, MB, GB e TB.                                                 |
| [`disk`](https://www.nextflow.io/docs/latest/process.html#disk)     | Permite definir a quantidade de armazenamento em disco local que a tarefa pode usar.                                                                                 |
| [`tag`](https://www.nextflow.io/docs/latest/process.html#tag)       | Permite associar cada execução de processo a um rótulo personalizado para facilitar sua identificação no arquivo de log ou no relatório de execução do rastreamento. |

## Organizando as saídas

### A diretiva PublishDir

Dado que cada tarefa está sendo executada em uma pasta `work/` temporária separada (por exemplo, `work/f1/850698…`; `work/g3/239712…`; etc.), podemos salvar informações importantes, não intermediárias, e/ou arquivos finais em uma pasta de resultados.

!!! tip

    Lembre-se de excluir a pasta de trabalho (`work`) de vez em quando para limpar seus arquivos intermediários e impedir que eles encham seu computador!

Para armazenar nossos arquivos de resultado do fluxo de trabalho, precisamos marcá-los explicitamente usando a diretiva [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir) no processo que está criando os arquivos. Por exemplo:

```groovy linenums="1"
params.diretorio_saida = 'meus-resultados'
params.prot = 'data/prots/*.tfa'
proteinas = Channel.fromPath(params.prot)


process BLASTSEQ {
    publishDir "$params.diretorio_saida/arquivos_bam", mode: 'copy'

    input:
    path fasta

    output:
    path ('*.txt')

    script:
    """
    echo blastp $fasta > ${fasta}_resultado.txt
    """
}

workflow {
    canal_blast = BLASTSEQ(proteinas)
    canal_blast.view()
}
```

O exemplo acima copiará todos os arquivos de script blast criados pelo processo `BLASTSEQ` no caminho do diretório `meus-resultados`.

!!! tip

    O diretório de publicação pode ser local ou remoto. Por exemplo, os arquivos de saída podem ser armazenados usando um [bucket AWS S3](https://aws.amazon.com/s3/) usando o prefixo `s3://` no caminho de destino.

### Gerenciando semântica de subdiretórios

Você pode usar mais de um `publishDir` para manter saídas diferentes em diretórios separados. Por exemplo:

```groovy linenums="1"
params.leituras = 'data/reads/*_{1,2}.fq.gz'
params.diretorio_saida = 'meus-resultados'

canal_amostras = Channel.fromFilePairs(params.leituras, flat: true)

process FOO {
    publishDir "$params.diretorio_saida/$id_amostra/", pattern: '*.fq'
    publishDir "$params.diretorio_saida/$id_amostra/contagens", pattern: "*_contagens.txt"
    publishDir "$params.diretorio_saida/$id_amostra/panoramas", pattern: '*_panorama.txt'

    input:
    tuple val(id_amostra), path('amostra1.fq.gz'), path('amostra2.fq.gz')

    output:
    path "*"

    script:
    """
    zcat amostra1.fq.gz > amostra1.fq
    zcat amostra2.fq.gz > amostra2.fq

    awk '{s++}END{print s/4}' amostra1.fq > amostra1_contagens.txt
    awk '{s++}END{print s/4}' amostra2.fq > amostra2_contagens.txt

    head -n 50 amostra1.fq > amostra1_panorama.txt
    head -n 50 amostra2.fq > amostra2_panorama.txt
    """
}

workflow {
    canal_saida = FOO(canal_amostras)
}
```

O exemplo acima criará uma estrutura de saída no diretório `meus-resultados`, que contém um subdiretório separado para cada ID de amostra fornecido, cada um contendo as pastas `contagens` e `panoramas`.
