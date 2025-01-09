---
description: Material de treinamento básico do Nextflow
---

# Canais

Canais são uma estrutura de dados chave do Nextflow que permite a implementação de fluxos de trabalho computacionais utilizando paradigmas funcional e reativo com base no paradigma de programação [Dataflow](https://en.wikipedia.org/wiki/Dataflow_programming).

Eles são usados para conectar logicamente tarefas entre si ou para implementar transformações de dados de estilo funcional.

<figure class="excalidraw">
--8<-- "docs/basic_training/img/channel-files.excalidraw.pt.svg"
</figure>

## Tipos de canais

O Nextflow distingue dois tipos diferentes de canais: canais de **fila** e canais de **valor**.

### Canal de fila

Um canal de _fila_ é uma fila assíncrona unidirecional FIFO (First-in-First-out, o primeiro a entrar, é o primeiro a sair) que conecta dois processos ou operadores.

-   _assíncrono_ significa que as operações ocorrem sem bloqueio.
-   _unidirecional_ significa que os dados fluem do gerador para o consumidor.
-   _FIFO_ significa que os dados são entregues na mesma ordem em que são produzidos. Primeiro a entrar, primeiro a sair.

Um canal de fila é criado implicitamente por definições de saída de um processo ou usando fábricas de canal, como o [Channel.of](https://www.nextflow.io/docs/latest/channel.html#of) ou [Channel.fromPath](https://www.nextflow.io/docs/latest/channel.html#frompath).

Tente os seguintes trechos de código:

!!! info ""

    Clique no ícone :material-plus-circle: no código para ver explicações.

```groovy linenums="1"
canal = Channel.of(1, 2, 3)
println(canal) // (1)!
canal.view() // (2)!
```

1. Use a função `println` embutida no Nextflow por padrão para imprimir o conteúdo do canal `canal`
2. Aplique o operador `view` no canal `canal` para imprimir cada emissão desse canal

!!! exercise

    Tente executar este trecho de código. Você pode fazer isso criando um novo arquivo `.nf` ou editando um arquivo `.nf` já existente.

    ```groovy linenums="1"
    canal = Channel.of(1, 2, 3)
    canal.view()
    ```

### Canais de valor

Um canal de **valor** (também conhecido como canal singleton), por definição, está vinculado a um único valor e pode ser lido quantas vezes for necessário sem consumir seu conteúdo. Um canal de `valor` é criado usando a fábrica de canal [value](https://www.nextflow.io/docs/latest/channel.html#value) ou por operadores que retornam um valor apenas, como [first](https://www.nextflow.io/docs/latest/operator.html#first), [last](https://www.nextflow.io/docs/latest/operator.html#last), [collect](https://www.nextflow.io/docs/latest/operator.html#operator-collect), [count](https://www.nextflow.io/docs/latest/operator.html#operator-count), [min](https://www.nextflow.io/docs/latest/operator.html#operator-min), [max](https://www.nextflow.io/docs/latest/operator.html#operator-max), [reduce](https://www.nextflow.io/docs/latest/operator.html#operator-reduce), e [sum](https://www.nextflow.io/docs/latest/operator.html#operator-sum).

Para entender melhor a diferença entre canais de valor e de fila, salve o trecho abaixo como `exemplo.nf`.

```groovy linenums="1" title="exemplo.nf" linenums="1"
canal1 = Channel.of(1, 2, 3)
canal2 = Channel.of(1)

process SUM {
    input:
    val x
    val y

    output:
    stdout

    script:
    """
    echo \$(($x+$y))
    """
}

workflow {
    SUM(canal1, canal2).view()
}
```

Ao rodar o script, ele imprime apenas 2, como você pode ver abaixo:

```console
2
```

Um processo só instanciará uma tarefa quando houver elementos a serem consumidos de _todos_ os canais fornecidos como entrada para ele. Como `canal1` e `canal2` são canais de fila, e o único elemento de `canal2` foi consumido, nenhuma nova instância de processo será iniciada, mesmo se houver outros elementos a serem consumidos em `canal1`.

Para usar o único elemento em `canal2` várias vezes, podemos usar `Channel.value` como mencionado acima, ou usar um operador de canal que retorna um único elemento como `first()` abaixo:

```groovy linenums="1"
canal1 = Channel.of(1, 2, 3)
canal2 = Channel.of(1)

process SUM {
    input:
    val x
    val y

    output:
    stdout

    script:
    """
    echo \$(($x+$y))
    """
}

workflow {
    SUM(canal1, canal2.first()).view()
}
```

```console title="Output"
4

3

2
```

Além disso, em muitas situações, o Nextflow converterá implicitamente variáveis em canais de valor quando forem usadas em uma chamada de processo. Por exemplo, quando você chama um processo com um parâmetro de fluxo de trabalho (`params.exemplo`) que possui um valor de string, ele é automaticamente convertido em um canal de valor.

## Fábricas de canal

Estes são comandos do Nextflow para criar canais que possuem entradas e funções implícitas esperadas.

### `value()`

A fábrica de canal `value` é utilizada para criar um canal de _valor_. Um argumento opcional não `nulo` pode ser especificado para vincular o canal a um valor específico. Por exemplo:

```groovy linenums="1"
canal1 = Channel.value() // (1)!
canal2 = Channel.value('Olá, você!') // (2)!
canal3 = Channel.value([1, 2, 3, 4, 5]) // (3)!
```

1. Cria um canal de valor _vazio_
2. Cria um canal de valor e vincula uma string a ele
3. Cria um canal de valor e vincula a ele um objeto de lista que será emitido como uma única emissão

### `of()`

A fábrica `Channel.of` permite a criação de um canal de fila com os valores especificados como argumentos.

```groovy linenums="1"
canal = Channel.of(1, 3, 5, 7)
canal.view { "numero: $it" }
```

A primeira linha neste exemplo cria uma variável `canal` que contém um objeto de canal. Este canal emite os valores especificados como parâmetro na fábrica de canal `of`. Assim, a segunda linha imprimirá o seguinte:

```console
numero: 1
numero: 3
numero: 5
numero: 7
```

A fábrica de canal `Channel.of` funciona de maneira semelhante ao `Channel.from` (que foi [descontinuado](https://www.nextflow.io/docs/latest/channel.html#of)), corrigindo alguns comportamentos inconsistentes do último e fornecendo um melhor manuseio quando um intervalo de valores é especificado. Por exemplo, o seguinte funciona com um intervalo de 1 a 23:

```groovy linenums="1"
Channel
    .of(1..23, 'X', 'Y')
    .view()
```

### `fromList()`

A fábrica de canal `Channel.fromList` cria um canal emitindo os elementos fornecidos por um objeto de lista especificado como um argumento:

```groovy linenums="1"
list = ['olá', 'mundo']

Channel
    .fromList(list)
    .view()
```

### `fromPath()`

A fábrica de canal `fromPath` cria um canal de fila emitindo um ou mais arquivos correspondentes ao padrão glob especificado.

```groovy linenums="1"
Channel.fromPath('./data/meta/*.csv')
```

Este exemplo cria um canal e emite tantos itens quanto arquivos com extensão `csv` existirem na pasta `./data/meta`. Cada elemento é um objeto de arquivo implementando a interface [Path](https://docs.oracle.com/javase/8/docs/api/java/nio/file/Paths.html) do Java.

!!! tip

    Dois asteriscos, ou seja, `**`, funcionam como `*`, mas cruzam os limites do diretório. Essa sintaxe geralmente é usada para percorrer caminhos completos. Os colchetes especificam uma coleção de subpadrões.

| Nome          | Descrição                                                                                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| glob          | Quando `true` interpreta caracteres `*`, `?`, `[]` e `{}` como glob wildcards, caso contrário, os trata como caracteres normais (padrão: `true`)             |
| type          | Tipo de caminho retornado, ou `file`, `dir` ou `any` (padrão: `file`)                                                                                        |
| hidden        | Quando `true` inclui arquivos ocultos nos caminhos resultantes (padrão: `false`)                                                                             |
| maxDepth      | Número máximo de níveis de diretório a serem visitados (padrão: `no limit`)                                                                                  |
| followLinks   | Quando `true` links simbólicos são seguidos durante a travessia da árvore de diretórios, caso contrário, eles são gerenciados como arquivos (padrão: `true`) |
| relative      | Quando `true` os caminhos de retorno são relativos ao diretório de topo mais comum (padrão: `false`)                                                         |
| checkIfExists | Quando `true` lança uma exceção quando o caminho especificado não existe no sistema de arquivos (padrão: `false`)                                            |

Saiba mais sobre a sintaxe dos padrões glob [neste link](https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob).

!!! exercise

    Use a fábrica de canal `Channel.fromPath` para criar um canal emitindo todos os arquivos com o sufixo `.fq` no diretório `data/ggal/` e qualquer subdiretório, além dos arquivos ocultos. Em seguida, imprima os nomes dos arquivos.

    ??? solution

        ```groovy linenums="1"
        Channel
            .fromPath('./data/ggal/**.fq', hidden: true)
            .view()
        ```

### `fromFilePairs()`

A fábrica de canal `fromFilePairs` cria um canal emitindo os pares de arquivos correspondentes a um padrão glob fornecido pelo usuário. Os arquivos correspondentes são emitidos como tuplas, nas quais o primeiro elemento é a chave de agrupamento do par correspondente e o segundo elemento é a lista de arquivos (classificados em ordem lexicográfica).

```groovy linenums="1"
Channel
    .fromFilePairs('./data/ggal/*_{1,2}.fq')
    .view()
```

Ele produzirá uma saída semelhante à seguinte:

```groovy
[liver, [/workspace/gitpod/nf-training/data/ggal/liver_1.fq, /workspace/gitpod/nf-training/data/ggal/liver_2.fq]]
[gut, [/workspace/gitpod/nf-training/data/ggal/gut_1.fq, /workspace/gitpod/nf-training/data/ggal/gut_2.fq]]
[lung, [/workspace/gitpod/nf-training/data/ggal/lung_1.fq, /workspace/gitpod/nf-training/data/ggal/lung_2.fq]]
```

!!! warning

    O padrão glob _precisa_ conter pelo menos um caractere curinga de estrela (`*`).

| Nome          | Descrição                                                                                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| type          | Tipo de caminhos retornados, ou `file`, `dir` ou `any` (padrão: `file`)                                                                                      |
| hidden        | Quando `true` inclui arquivos ocultos nos caminhos resultantes (padrão: `false`)                                                                             |
| maxDepth      | Número máximo de níveis de diretório a serem visitados (padrão: `no limit`)                                                                                  |
| followLinks   | Quando `true` links simbólicos são seguidos durante a travessia da árvore de diretórios, caso contrário, eles são gerenciados como arquivos (padrão: `true`) |
| size          | Define o número de arquivos que cada item emitido deve conter (padrão: `2`). Use `-1` para qualquer número                                                   |
| flat          | Quando `true` os arquivos correspondentes são produzidos como únicos elementos nas tuplas emitidas (padrão: `false`)                                         |
| checkIfExists | Quando `true` lança uma exceção quando o caminho especificado não existe no sistema de arquivos (padrão: `false`)                                            |

!!! exercise

    Use a fábrica de canal `fromFilePairs` para criar um canal emitindo todos os pares de leituras em fastq no diretório `data/ggal/` e imprima-os. Em seguida, use a opção `flat: true` e compare a saída com a execução anterior.

    ??? solution

        Use o seguinte, com ou sem `flat: true`:

        ```groovy linenums="1"
        Channel
            .fromFilePairs('./data/ggal/*_{1,2}.fq', flat: true)
            .view()
        ```

        Em seguida, verifique os colchetes ao redor dos nomes dos arquivos, para ver a diferença com `flat`.

### `fromSRA()`

A fábrica de canal `Channel.fromSRA` permite consultar o banco de dados [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra) e retorna um canal que emite os arquivos FASTQ correspondentes aos critérios de seleção especificados.

A consulta pode ser ID(s) de projeto(s) ou número(s) de acesso suportado(s) pela API do [NCBI ESearch](https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESearch).

!!! info

    Esta função agora requer uma chave de API que você só pode obter fazendo login em sua conta NCBI.

??? example "Instruções para login do NCBI e aquisição de chave"

    1. Vá para: <https://www.ncbi.nlm.nih.gov/>
    2. Clique no botão "Login" no canto superior direito para entrar no NCBI. Siga suas instruções.
    3. Uma vez em sua conta, clique no botão no canto superior direito, geralmente seu ID.
    4. Vá para Account settings
    5. Role para baixo até a seção "API Key Management".
    6. Clique em "Create an API Key".
    7. A página será atualizada e a chave será exibida onde estava o botão. Copie sua chave.

Por exemplo, o trecho a seguir imprimirá o conteúdo de um ID de projeto NCBI:

```groovy linenums="1"
params.ncbi_api_key = '<Sua chave da API aqui>'

Channel
    .fromSRA(['SRP073307'], apiKey: params.ncbi_api_key)
    .view()
```

!!! info ""

    :material-lightbulb: Substitua `<Sua chave de API aqui>` com sua chave de API.

Isso deve imprimir:

```groovy
[SRR3383346, [/vol1/fastq/SRR338/006/SRR3383346/SRR3383346_1.fastq.gz, /vol1/fastq/SRR338/006/SRR3383346/SRR3383346_2.fastq.gz]]
[SRR3383347, [/vol1/fastq/SRR338/007/SRR3383347/SRR3383347_1.fastq.gz, /vol1/fastq/SRR338/007/SRR3383347/SRR3383347_2.fastq.gz]]
[SRR3383344, [/vol1/fastq/SRR338/004/SRR3383344/SRR3383344_1.fastq.gz, /vol1/fastq/SRR338/004/SRR3383344/SRR3383344_2.fastq.gz]]
[SRR3383345, [/vol1/fastq/SRR338/005/SRR3383345/SRR3383345_1.fastq.gz, /vol1/fastq/SRR338/005/SRR3383345/SRR3383345_2.fastq.gz]]
// (o restante foi omitido)
```

Vários IDs de acesso podem ser especificados usando um objeto lista:

```groovy linenums="1"
ids = ['ERR908507', 'ERR908506', 'ERR908505']
Channel
    .fromSRA(ids, apiKey: params.ncbi_api_key)
    .view()
```

```groovy
[ERR908507, [/vol1/fastq/ERR908/ERR908507/ERR908507_1.fastq.gz, /vol1/fastq/ERR908/ERR908507/ERR908507_2.fastq.gz]]
[ERR908506, [/vol1/fastq/ERR908/ERR908506/ERR908506_1.fastq.gz, /vol1/fastq/ERR908/ERR908506/ERR908506_2.fastq.gz]]
[ERR908505, [/vol1/fastq/ERR908/ERR908505/ERR908505_1.fastq.gz, /vol1/fastq/ERR908/ERR908505/ERR908505_2.fastq.gz]]
```

!!! info

    Os pares de leituras são gerenciados implicitamente e são retornados como uma lista de arquivos.

É fácil usar este canal como uma entrada usando a sintaxe usual do Nextflow. O código abaixo cria um canal contendo
duas amostras de um estudo SRA público e executa o FASTQC nos arquivos resultantes. Veja:

```groovy linenums="1"
params.ncbi_chave_api = '<Sua chave de API aqui>'

params.accession = ['ERR908507', 'ERR908506']

process FASTQC {
    input:
    tuple val(id_amostra), path(arquivo_de_leituras)

    output:
    path("fastqc_${id_amostra}_logs")

    script:
    """
    mkdir fastqc_${id_amostra}_logs
    fastqc -o fastqc_${id_amostra}_logs -f fastq -q ${arquivo_de_leituras}
    """
}

workflow {
    leituras = Channel.fromSRA(params.accession, apiKey: params.ncbi_chave_api)
    FASTQC(leituras)
}
```

Se você deseja executar o fluxo de trabalho acima e não possui o fastqc instalado em sua máquina, não esqueça o que aprendeu na seção anterior. Execute este fluxo de trabalho com `-with-docker biocontainers/fastqc:v0.11.5`, por exemplo.

### Arquivos de texto

O operador `splitText` permite dividir strings de várias linhas ou itens de arquivo de texto, emitidos por um canal de origem em blocos contendo n linhas, que serão emitidos pelo canal resultante. Veja:

```groovy linenums="1"
Channel
    .fromPath('data/meta/random.txt') // (1)!
    .splitText() // (2)!
    .view() // (3)!
```

1. Instrui o Nextflow a criar um canal a partir do caminho `data/meta/random.txt`
2. O operador `splitText` divide cada item em pedaços de uma linha por padrão.
3. Veja o conteúdo do canal.

Você pode definir o número de linhas em cada bloco usando o parâmetro `by`, conforme mostrado no exemplo a seguir:

```groovy linenums="1"
Channel
    .fromPath('data/meta/random.txt')
    .splitText(by: 2)
    .subscribe {
        print it;
        print "--- fim do bloco ---\n"
    }
```

!!! info

    O operador `subscribe` permite a execução de funções definidas pelo usuário cada vez que um novo valor é emitido pelo canal de origem.

Uma clausura opcional pode ser especificada para transformar os blocos de texto produzidos pelo operador. O exemplo a seguir mostra como dividir arquivos de texto em blocos de 10 linhas e transformá-los em letras maiúsculas:

```groovy linenums="1"
Channel
    .fromPath('data/meta/random.txt')
    .splitText(by: 10) { it.toUpperCase() }
    .view()
```

Você também pode fazer contagens para cada linha:

```groovy linenums="1"
contador = 0

Channel
    .fromPath('data/meta/random.txt')
    .splitText()
    .view { "${contador++}: ${it.toUpperCase().trim()}" }
```

Por fim, você também pode usar o operador em arquivos simples (fora do contexto do canal):

```groovy linenums="1"
def f = file('data/meta/random.txt')
def linhas = f.splitText()
def contador = 0
for (String linha : linhas) {
    log.info "${contador++} ${linha.toUpperCase()}"
}
```

### Valores separados por vírgula (.csv)

O operador `splitCsv` permite analisar itens de texto formatados em CSV (Comma-separated value) emitidos por um canal.

Em seguida, ele os divide em registros ou os agrupa como uma lista de registros com um comprimento especificado.

No caso mais simples, basta aplicar o operador `splitCsv` a um canal que emite arquivos de texto ou entradas de texto no formato CSV. Por exemplo, para visualizar apenas a primeira e a quarta colunas:

```groovy linenums="1"
Channel
    .fromPath("data/meta/patients_1.csv")
    .splitCsv()
    // linha é um objeto de lista
    .view { linha -> "${linha[0]}, ${linha[3]}" }
```

Quando o CSV começa com uma linha de cabeçalho definindo os nomes das colunas, você pode especificar o parâmetro `header: true` que permite referenciar cada valor pelo nome da coluna, conforme mostrado no exemplo a seguir:

```groovy linenums="1"
Channel
    .fromPath("data/meta/patients_1.csv")
    .splitCsv(header: true)
    // linha é um objeto de lista
    .view { linha -> "${linha.patient_id}, ${linha.num_samples}" }
```

Como alternativa, você pode fornecer nomes de cabeçalho personalizados especificando uma lista de strings no parâmetro de cabeçalho, conforme mostrado abaixo:

```groovy linenums="1"
Channel
    .fromPath("data/meta/patients_1.csv")
    .splitCsv(header: ['col1', 'col2', 'col3', 'col4', 'col5'])
    // linha é um objeto de lista
    .view { linha -> "${linha.col1}, ${linha.col4}" }
```

Você também pode processar vários arquivos CSV ao mesmo tempo:

```groovy linenums="1"
Channel
    .fromPath("data/meta/patients_*.csv") // <-- use um padrão de captura
    .splitCsv(header: true)
    .view { linha -> "${linha.patient_id}\t${linha.num_samples}" }
```

!!! tip

    Observe que você pode alterar o formato de saída simplesmente adicionando um delimitador diferente.

Por fim, você também pode operar em arquivos CSV fora do contexto do canal:

```groovy linenums="1"
def f = file('data/meta/patients_1.csv')
def linhas = f.splitCsv()
for (List linha : linhas) {
    log.info "${linha[0]} -- ${linha[2]}"
}
```

!!! exercise

    Tente inserir leituras fastq no fluxo de trabalho do RNA-Seq anterior usando `.splitCsv`.

    ??? solution

        Adicione um arquivo de texto CSV contendo o seguinte, como uma entrada de exemplo com o nome "fastq.csv":

        ```csv
        gut,/workspace/gitpod/nf-training/data/ggal/gut_1.fq,/workspace/gitpod/nf-training/data/ggal/gut_2.fq
        ```

        Em seguida, substitua o canal de entrada para as leituras em `script7.nf`, alterando as seguintes linhas:

        ```groovy linenums="1"
        Channel
            .fromFilePairs(params.reads, checkIfExists: true)
            .set { read_pairs_ch }
        ```

        Para uma entrada de fábrica de canal splitCsv:

        ```groovy linenums="1" hl_lines="2 3 4"
        Channel
            .fromPath("fastq.csv")
            .splitCsv()
            .view { linha -> "${linha[0]}, ${linha[1]}, ${linha[2]}" }
            .set { read_pairs_ch }
        ```

        Por fim, altere a cardinalidade dos processos que usam os dados de entrada. Por exemplo, para o processo de quantificação, mude de:

        ```groovy linenums="1"
        process QUANTIFICATION {
            tag "$sample_id"

            input:
            path salmon_index
            tuple val(sample_id), path(reads)

            output:
            path sample_id, emit: quant_ch

            script:
            """
            salmon quant --threads $task.cpus --libType=U -i $salmon_index -1 ${reads[0]} -2 ${reads[1]} -o $sample_id
            """
        }
        ```

        Para:

        ```groovy linenums="1" hl_lines="6 13"
        process QUANTIFICATION {
            tag "$sample_id"

            input:
            path salmon_index
            tuple val(sample_id), path(reads1), path(reads2)

            output:
            path sample_id, emit: quant_ch

            script:
            """
            salmon quant --threads $task.cpus --libType=U -i $salmon_index -1 ${reads1} -2 ${reads2} -o $sample_id
            """
        }
        ```

        Repita o procedimento acima para a etapa fastqc.

        ```groovy linenums="1" hl_lines="5 13"
        process FASTQC {
            tag "FASTQC on $sample_id"

            input:
            tuple val(sample_id), path(reads1), path(reads2)

            output:
            path "fastqc_${sample_id}_logs"

            script:
            """
            mkdir fastqc_${sample_id}_logs
            fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads1} ${reads2}
            """
        }
        ```

        Agora o fluxo de trabalho deve ser executado a partir de um arquivo CSV.

### Valores separados por tabulação (.tsv)

A análise de arquivos TSV funciona de maneira semelhante, basta adicionar a opção `sep: '\t'` no contexto do `splitCsv`:

```groovy linenums="1"
Channel
    .fromPath("data/meta/regions.tsv", checkIfExists: true)
    // Use a opção `sep` para analisar arquivos com tabulação como separador
    .splitCsv(sep: '\t')
    .view()
```

!!! exercise

    Tente usar a técnica de separação por tabulação no arquivo `data/meta/regions.tsv`, mas imprima apenas a primeira coluna e remova o cabeçalho.


    ??? solution

        ```groovy linenums="1"
        Channel
            .fromPath("data/meta/regions.tsv", checkIfExists: true)
            // Use a opção `sep` para analisar arquivos com tabulação como separador
            .splitCsv(sep: '\t', header: true)
            // linha é um objeto de lista
            .view { linha -> "${linha.patient_id}" }
        ```

## Formatos de arquivo mais complexos

### JSON

Também podemos analisar facilmente o formato de arquivo JSON usando o oeprador de canal `splitJson`.

O operador `splitJson` suporta arranjos JSON:

=== "Código-fonte"

    ```groovy linenums="1"
    Channel
        .of('["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]')
        .splitJson()
        .view { "Item: ${it}" }
    ```

=== "Saída"

    ```console
    Item: Domingo
    Item: Segunda
    Item: Terça
    Item: Quarta
    Item: Quinta
    Item: Sexta
    Item: Sábado
    ```

Objetos JSON:

=== "Código-fonte"

    ```groovy linenums="1"
    Channel
        .of('{"jogador": {"nome": "Bob", "altura": 180, "venceu_campeonato": false}}')
        .splitJson()
        .view { "Item: ${it}" }
    ```

=== "Saída"

    ```console
    Item: [key:jogador, value:[nome:Bob, altura:180, venceu_campeonato:false]]
    ```

E inclusive arranjos JSON com objetos JSON!

=== "Código-fonte"

    ```groovy linenums="1"
    Channel
        .of('[{"nome": "Bob", "altura": 180, "venceu_campeonato": false}, \
            {"nome": "Alice", "height": 170, "venceu_campeonato": false}]')
        .splitJson()
        .view { "Item: ${it}" }
    ```

=== "Saída"

    ```console
    Item: [nome:Bob, altura:180, venceu_campeonato:false]
    Item: [nome:Alice, altura:170, venceu_campeonato:false]
    ```

Arquivos contendo dados em formato JSON também podem ser analisados:

=== "Código-fonte"

    ```groovy linenums="1"
    Channel
        .fromPath('arquivo.json')
        .splitJson()
        .view { "Item: ${it}" }
    ```

=== "arquivo.json"

    ```json
    [{"nome": "Bob", "altura": 180, "venceu_campeonato": false}, {"nome": "Alice", "altura": 170, "venceu_campeonato": false}]
    ```

=== "Saída"

    ```console
    Item: [nome:Bob, altura:180, venceu_campeonato:false]
    Item: [nome:Alice, altura:170, venceu_campeonato:false]
    ```

### YAML

Isso também pode ser usado como uma forma de analisar arquivos YAML:

=== "Código-fonte"

    ```groovy linenums="1"
    import org.yaml.snakeyaml.Yaml

    def f = file('data/meta/regions.yml')
    def registros = new Yaml().load(f)

    for (def entrada : registros) {
        log.info "$entrada.patient_id -- $entrada.feature"
    }

    ```

=== "data/meta/regions.yml"

    ```yaml
    --8<-- "nf-training/data/meta/regions.yml"
    ```

=== "Saída"

    ```console
    ATX-TBL-001-GB-01-105 -- pass_vafqc_flag
    ATX-TBL-001-GB-01-105 -- pass_stripy_flag
    ATX-TBL-001-GB-01-105 -- pass_manual_flag
    ATX-TBL-001-GB-01-105 -- other_region_selection_flag
    ATX-TBL-001-GB-01-105 -- ace_information_gained
    ATX-TBL-001-GB-01-105 -- concordance_flag
    ATX-TBL-001-GB-01-105 -- pass_vafqc_flag
    ATX-TBL-001-GB-01-105 -- pass_stripy_flag
    ATX-TBL-001-GB-01-105 -- pass_manual_flag
    ATX-TBL-001-GB-01-105 -- other_region_selection_flag
    ATX-TBL-001-GB-01-105 -- ace_information_gained
    ATX-TBL-001-GB-01-105 -- concordance_flag
    ATX-TBL-001-GB-01-105 -- pass_vafqc_flag
    ATX-TBL-001-GB-01-105 -- pass_stripy_flag
    ```

### Armazenamento em módulos de analisadores sintáticos

A melhor maneira de armazenar scripts com analisadores é mantê-los em um arquivo de módulo Nextflow.

Digamos que não temos um operador de canal JSON, mas criamos uma função para isso. O arquivo `parsers.nf` deve conter a função `parseArquivoJson`. Veja o conteúdo abaixo:

=== "Código-fonte"

    ```groovy linenums="1"
    include { parseArquivoJson } from './modules/parsers.nf'

    process FOO {
        input:
        tuple val(id_paciente), val(caracteristica)

        output:
        stdout

        script:
        """
        echo $id_paciente tem $caracteristica como coluna
        """
    }

    workflow {
        Channel
            .fromPath('data/meta/regions*.json')
            | flatMap { parseArquivoJson(it) }
            | map { registro -> [registro.patient_id, registro.feature] }
            | unique
            | FOO
            | view
    }
    ```

=== "./modules/parsers.nf"

    ```groovy linenums="1"
    import groovy.json.JsonSlurper

    def parseArquivoJson(arquivo_json) {
        def f = file(arquivo_json)
        def registros = new JsonSlurper().parse(f)
        return registros
    }
    ```

=== "Saída"

    ```console
    ATX-TBL-001-GB-01-105 tem pass_stripy_flag como coluna

    ATX-TBL-001-GB-01-105 tem ace_information_gained como coluna

    ATX-TBL-001-GB-01-105 tem concordance_flag como coluna

    ATX-TBL-001-GB-01-105 tem pass_vafqc_flag como coluna

    ATX-TBL-001-GB-01-105 tem pass_manual_flag como coluna

    ATX-TBL-001-GB-01-105 tem other_region_selection_flag como coluna
    ```

O Nextflow usará isso como uma função personalizada dentro do escopo `workflow`.

!!! tip

    Você aprenderá mais sobre arquivos de módulo posteriormente na [seção de Modularização](../modules/) desse tutorial.
