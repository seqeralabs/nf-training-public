---
description: Material de treinamento básico do Nextflow
---

# Fluxo de trabalho simples de RNA-Seq

Para demonstrar um cenário biomédico da vida real, nós iremos implementar uma prova de conceito de fluxo de trabalho RNA-Seq que:

1. Cria arquivo de índice de transcriptoma
2. Realiza controles de qualidade
3. Realiza quantificação
4. Cria um relatório MultiQC

Isso será feito usando uma série de sete scripts, cada um se baseando no script anterior, para criar um fluxo de trabalho completo. Você poderá encontrá-los no diretório do tutorial (`script1.nf` - `script7.nf`). Esses scripts farão uso de ferramentas de terceiros que são conhecidas por bioinformatas, mas que podem ser novas para você, então vamos apresentá-las brevemente abaixo.

1. [Salmon](https://combine-lab.github.io/salmon/) é uma ferramenta para quantificar moléculas conhecidas como transcritos por meio de um tipo de dados chamado dados de RNA-seq.
2. [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) é uma ferramenta para executar o controle de qualidade para dados de sequenciamento de alta vazão. Você pode pensar nisso como uma forma de avaliar a qualidade de seus dados.
3. [MultiQC](https://multiqc.info) pesquisa um determinado diretório por logs de análises e compila um relatório HTML. É uma ferramenta de uso geral, perfeita para resumir a saída de várias ferramentas de bioinformática.

Embora essas ferramentas possam não ser as que você usará em seu pipeline, elas podem ser substituídas por qualquer ferramenta comum de sua área. Esse é o poder do Nextflow!

## Defina os parâmetros do fluxo de trabalho

Parâmetros são entradas e opções que podem ser modificadas quando um fluxo de trabalho é executado.

O script `script1.nf` define os parâmetros de entrada do fluxo de trabalho.

```groovy
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"

println "reads: $params.reads"
```

Execute-o usando o comando a seguir:

```bash
nextflow run script1.nf
```

Tente especificar um parâmetro de entrada diferente no seu comando de execução, por exemplo:

```bash
nextflow run script1.nf --reads '/workspace/gitpod/nf-training/data/ggal/lung_{1,2}.fq'
```

### :material-progress-question: Exercícios

!!! exercise

    Modifique o `script1.nf` ao adicionar um quarto parâmetro chamado `outdir` e defina-o como um caminho padrão que será usado como o diretório de saída do fluxo de trabalho.

    ??? Solution

        ```groovy
        params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
        params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
        params.multiqc = "$projectDir/multiqc"
        params.outdir = "results"
        ```

!!! exercise

    Modifique o `script1.nf` para imprimir todos os parâmetros do fluxo de trabalho usando um único comando`log.info` como uma declaração de [string multilinha](https://www.nextflow.io/docs/latest/script.html#multi-line-strings).

    !!! tip ""

        :material-lightbulb: Veja um exemplo [aqui](https://github.com/nextflow-io/rnaseq-nf/blob/3b5b49f/main.nf#L41-L48).


    ??? Solution

        Adicione o código abaixo para seu arquivo de script:

        ```groovy
        log.info """\
            R N A S E Q - N F   P I P E L I N E
            ===================================
            transcriptome: ${params.transcriptome_file}
            reads        : ${params.reads}
            outdir       : ${params.outdir}
            """
            .stripIndent(true)
        ```

### :material-check-all: Resumo

Nesta etapa você aprendeu:

1. Como definir parâmetros em seu script de fluxo de trabalho
2. Como atribuir parâmetros usando a linha de comando
3. O uso de `$var` e `${var}` como espaço reservado para variáveis
4. Como usar strings multilinhas
5. Como usar `log.info` para imprimir informações e salvá-las no arquivo de execução de log

## Crie um arquivo de índice de transcriptoma

O Nextflow permite a execução de qualquer comando ou script usando uma definição de processo (`process`).

Um processo é definido por três principais declarações: as entradas ([`input`](https://www.nextflow.io/docs/latest/process.html#inputs)), saídas ([`output`](https://www.nextflow.io/docs/latest/process.html#outputs)) e comandos de [`script`](https://www.nextflow.io/docs/latest/process.html#script) do processo.

Para adicionar uma etapa de processamento de índice do transcriptoma (`INDEX`), tente adicionar os blocos de código a seguir no seu `script1.nf`. Como alternativa, esses blocos de código já foram adicionados ao `script2.nf`.

```groovy
/*
 * define o processo INDEX que cria um índice binário
 * dado um arquivo de transcriptoma
 */
process INDEX {
    input:
    path transcriptome

    output:
    path 'salmon_index'

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i salmon_index
    """
}
```

Além disso, adicione um escopo `workflow` contendo uma definição de canal de entrada e o processo de índice:

```groovy
workflow {
    index_ch = INDEX(params.transcriptome_file)
}
```

Aqui, o parâmetro `params.transcriptome_file` é usado como entrada para o processo `INDEX`. O processo `INDEX` (usando a ferramenta `salmon`) cria um arquivo chamado `salmon_index`, que é um arquivo de índice de transcriptoma que é passado como saída ao canal `index_ch`.

!!! info

    A declaração de entrada define a variável `transcriptome` com o qualificador `path` que é usada no `script` como uma referência (usando o símbolo de cifrão) na linha de comando do Salmon.

!!! warning

    Os requisitos de recursos, como CPUs e limites de memória, podem mudar com diferentes execuções do fluxo de trabalho e plataformas. O Nextflow pode usar `$task.cpus` como uma variável para o número de CPUs. Veja a [documentação de diretivas de processo](https://www.nextflow.io/docs/latest/process.html#directives) para mais detalhes.

Execute-o usando o comando:

```bash
nextflow run script2.nf
```

A execução irá falhar porque o `salmon` não está instalado em seu ambiente.

Adicione a opção de linha de comando `-with-docker` para iniciar a execução através do contêiner Docker, como mostrado abaixo:

```bash
nextflow run script2.nf -with-docker
```

Dessa vez a execução vai funcionar porque usa o contêiner Docker `nextflow/rnaseq-nf` que é definido no arquivo `nextflow.config` do seu diretório atual. Se você está executando esse script localmente, você precisará baixar o Docker em seu computador, fazer login e ativar o Docker, e permitir que o script baixe o contêiner contendo os scripts de execução. Você pode aprender mais sobre o Docker na documentação oficial do Nextflow [aqui](https://www.nextflow.io/docs/latest/docker.html).

Para evitar adicionar `-with-docker` cada vez que você executar o script, adicione a linha a seguir ao arquivo `nextflow.config`:

```groovy
docker.enabled = true
```

### :material-progress-question: Exercícios

!!! exercise

    Ative a execução do Docker por padrão adicionando a configuração acima no arquivo `nextflow.config`.

!!! exercise

    Imprima a saída do canal `index_ch` usando o operador [view](https://www.nextflow.io/docs/latest/operator.html#view).

    ??? Solution

        Adicione o código a seguir ao final do bloco `workflow` em seu arquivo de script

        ```groovy
        index_ch.view()
        ```

!!! exercise

    Se você tiver mais CPUs disponíveis, tente alterar seu script para solicitar mais recursos para este processo. Por exemplo, consulte os [documentos de diretivas](https://www.nextflow.io/docs/latest/process.html#cpus). `$task.cpus` já está especificado no script, portanto definir o número de CPUs como uma diretiva informará ao Nextflow para executar este processo levando isso em consideração.

    ??? Solution

        Adicione `cpus 2` no top do processo de índice:

        ```groovy
        process INDEX {
            cpus 2

            input:
            ...
        ```

        Em seguida verifique se funcionou observando o script executado no diretório de trabalho. Procure pelo hexadecimal (por exemplo, `work/7f/f285b80022d9f61e82cd7f90436aa4/`), depois use `cat` no arquivo `.command.sh`.

!!! exercise "Bonus Exercise"

    Use o comando `tree work` para observar como o Nextflow organiza o diretório de trabalho do processo. Leia mais [aqui](https://www.tecmint.com/linux-tree-command-examples/) se você precisa baixar o `tree`.

    ??? Solution

        Você deve ver algo parecido com a saída abaixo:

        ```
        work
        ├── 17
        │   └── 263d3517b457de4525513ae5e34ea8
        │       ├── index
        │       │   ├── complete_ref_lens.bin
        │       │   ├── ctable.bin
        │       │   ├── ctg_offsets.bin
        │       │   ├── duplicate_clusters.tsv
        │       │   ├── eqtable.bin
        │       │   ├── info.json
        │       │   ├── mphf.bin
        │       │   ├── pos.bin
        │       │   ├── pre_indexing.log
        │       │   ├── rank.bin
        │       │   ├── refAccumLengths.bin
        │       │   ├── ref_indexing.log
        │       │   ├── reflengths.bin
        │       │   ├── refseq.bin
        │       │   ├── seq.bin
        │       │   └── versionInfo.json
        │       └── transcriptome.fa -> /workspace/Gitpod_test/data/ggal/transcriptome.fa
        ├── 7f
        ```

### :material-check-all: Resumo

Nesta etapa você aprendeu:

1. Como definir um processo executando um comando personalizado
2. Como as entradas do processo são declaradas
3. Como as saídas do processo são declaradas
4. Como imprimir o conteúdo de um canal
5. Como acessar o número de CPUs disponíveis

## Colete arquivos de leitura por pares

Essa etapa mostra como combinar arquivos de **leitura** em pares, para que eles possam ser mapeados pelo **Salmon**.

Edite o script `script3.nf` adicionando a seguinte declaração como a última linha do arquivo:

```groovy
read_pairs_ch.view()
```

Salve-o e execute-o com o comando a seguir:

```bash
nextflow run script3.nf
```

Isso irá imprimir algo semelhante a isso:

```bash
[gut, [/.../data/ggal/gut_1.fq, /.../data/ggal/gut_2.fq]]
```

O exemplo acima mostra como o canal `read_pairs_ch` emite tuplas compostas de dois elementos, onde o primeiro é o prefixo do par de leitura e o segundo é uma lista que representa os arquivos de fato.

Tente novamente especificando arquivos de leituras diferentes usando um padrão glob:

```bash
nextflow run script3.nf --reads 'data/ggal/*_{1,2}.fq'
```

!!! warning

    Caminhos de arquivo que incluem um ou mais caracteres especiais, como `*`, `?` etc., DEVEM ser colocados entre aspas simples para evitar que o Bash expanda o glob.

### :material-progress-question: Exercícios

!!! exercise

    Use o operador [set](https://www.nextflow.io/docs/latest/operator.html#set) no lugar da atribuição `=` para definir o canal `read_pairs_ch`.

    ??? Solution

        ```groovy
        Channel
            .fromFilePairs(params.reads)
            .set { read_pairs_ch }
        ```

!!! exercise

    Use a opção `checkIfExists` para a fábrica de canal [fromFilePairs](https://www.nextflow.io/docs/latest/channel.html#fromfilepairs) para checar se o caminho especificado contém os pares de arquivos.

    ??? Solution

        ```groovy
        Channel
            .fromFilePairs(params.reads, checkIfExists: true)
            .set { read_pairs_ch }
        ```

### :material-check-all: Resumo

Nessa etapa você aprendeu:

1. Como usar `fromFilePairs` para lidar com pares de arquivos de leituras
2. Como usar a opção `checkIfExists` para checar a existência de arquivos de entrada
3. Como usar o operador `set` para definir uma uma nova variável de canal

!!! info

    A declaração de um canal pode ser feita antes do escopo `workflow` ou dentro dele. Desde que a declaração esteja acima do processo que requer o canal específico.

## Realize a quantificação da expressão

O script `script4.nf` adiciona um processo de quantificação de expressão gênica (`QUANTIFICATION`) e uma chamada para esse processo dentro do escopo `workflow`. A quantificação requer o arquivo de índice de transcriptoma e os arquivos fastq do par de leitura de RNA-Seq.

No escopo `workflow`, observe como o canal `index_ch` é designado como saída do processo `INDEX`.

A seguir, note que o primeiro canal de entrada para o processo de `QUANTIFICATION` é o `index_ch` declarado previamente, que contém o caminho para o arquivo `salmon_index`.

Além disso, observe que o segundo canal de entrada para o processo `QUANTIFICATION` é o `read_pair_ch` que acabamos de criar. Este sendo uma `tupla` composta de dois elementos (um valor: `sample_id` e a lista de caminhos para os arquivos de leituras fastq: `reads`) para corresponder à estrutura dos itens emitidos pela fábrica de canais `fromFilePairs`.

Execute-o usando o comando a seguir:

```bash
nextflow run script4.nf -resume
```

Você irá ver a execução do processo `QUANTIFICATION`.

Ao usar a opção `-resume`, qualquer etapa que já foi processada é ignorada.

Tente executar o mesmo script novamente com mais arquivos de leituras, como mostrado abaixo:

```bash
nextflow run script4.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

Você irá perceber que o processo `QUANTIFICATION` é executado múltiplas vezes.

O Nextflow paraleliza a execução de seu fluxo de trabalho simplesmente fornecendo vários conjuntos de dados de entrada para seu script.

!!! tip

    Pode ser útil aplicar configurações opcionais a um processo específico usando [diretivas](https://www.nextflow.io/docs/latest/process.html#directives) especificando-as no corpo do processo.

### :material-progress-question: Exercícios

!!! exercise

    Adicione uma diretiva de [tag](https://www.nextflow.io/docs/latest/process.html#tag), ao processo `QUANTIFICATION` para fornecer um log de execução mais legível.

    ??? Solution

        Adicione o código a seguir antes da declaração de entrada:

        ```groovy
        tag "Salmon on $sample_id"
        ```

!!! exercise

    Adicione a diretiva [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir) para o processo `QUANTIFICATION` para armazenar os resultados do processo em um diretório de sua escolha.

    ??? Solution

        Adicione o código a seguir antes da declaração de entrada no processo de `QUANTIFICATION`:

        ```groovy
        publishDir params.outdir, mode: 'copy'
        ```

### :material-check-all: Resumo

Nessa etapa você aprendeu:

1. Como conectar dois processos juntos usando declarações de canal
2. Como retomar a execução do script e pular etapas em cache
3. Como usar a diretiva `tag` para fornecer uma saída de execução mais legível
4. Como usar a diretiva `publishDir` para armazenar os resultados do processo em um caminho da sua escolha

## Controle de qualidade

A seguir, nós implementamos uma etapa de controle de qualidade `FASTQC` para seus arquivos de leituras de entrada (usando a etiqueta `fastqc`). As entradas são as mesmas que os pares de arquivos de leituras na etapa `QUANTIFICATION`.

Você pode executá-lo usando o comando a seguir:

```bash
nextflow run script5.nf -resume
```

O Nextflow DSL2 sabe como dividir `reads_pair_ch` em dois canais idênticos, já que eles são requiridos duas vezes como entrada para os processos `FASTQC` e `QUANTIFICATION`.

## Relatório MultiQC

Essa etapa coleta as saídas dos processos `QUANTIFICATION` e `FASTQC` para criar um relatório final usando a ferramenta [MultiQC](http://multiqc.info/).

Execute o próximo script com o comando a seguir:

```bash
nextflow run script6.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

Isso cria um relatório final na pasta `results` no diretório de trabalho atual.

Neste script, observe o uso dos operadores [mix](https://www.nextflow.io/docs/latest/operator.html#mix) e [collect](https://www.nextflow.io/docs/latest/operator.html#collect) de forma encadeada para reunir as saídas dos processos `QUANTIFICATION` e `FASTQC` como uma única entrada. [Operadores](https://www.nextflow.io/docs/latest/operator.html) podem ser usados para combinar e transformar canais.

```groovy
MULTIQC(quant_ch.mix(fastqc_ch).collect())
```

Queremos que apenas uma tarefa do MultiQC seja executada para produzir um relatório. Portanto, usamos o operador de canal `mix` para combinar os dois canais, seguido pelo operador `collect` para retornar os conteúdos completos do canal como um único elemento.

### :material-check-all: Resumo

Nessa etapa você aprendeu:

1. Como coletar várias saídas para uma única entrada com o operador `collect`
2. Como combinar com `mix` dois canais em um único canal
3. Como encadear dois ou mais operadores juntos

## Lide com evento de conclusão

Essa etapa mostra como executar uma ação quando o fluxo de trabalho completa a execução.

Observe que processos do Nextflow definem a execução de tarefas assíncronas, ou seja, elas não são executadas uma após a outra como se elas fossem escritas no script do fluxo de trabalho em uma linguagem de programação **imperativa** comum.

O script usa o manipulador de evento `workflow.onComplete` para imprimir uma mensagem de confirmação quando o script for concluído.

Tente executá-lo usando o comando a seguir:

```bash
nextflow run script7.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

## Notificações por email

Envie uma notificação por email quando a execução do fluxo de trabalho for concluída usando a opção de linha de comando `-N <endereço de email>`.

Nota: isso requer a configuração de um servidor SMTP no arquivo de configuração do Nextflow. Abaixo há um exemplo de um arquivo `nextflow.config` mostrando as configurações que você teria que configurar:

```groovy
mail {
    from = 'info@nextflow.io'
    smtp.host = 'email-smtp.eu-west-1.amazonaws.com'
    smtp.port = 587
    smtp.user = "xxxxx"
    smtp.password = "yyyyy"
    smtp.auth = true
    smtp.starttls.enable = true
    smtp.starttls.required = true
}
```

Veja a [documentação de email](https://www.nextflow.io/docs/latest/mail.html#mail-configuration) para mais detalhes.

## Scripts personalizados

Os fluxos de trabalho do mundo real usam muitos scripts de usuário personalizados (BASH, R, Python, etc.). O Nextflow permite que você use e gerencie consistentemente esses scripts. Simplesmente os coloque em um diretório chamado `bin` na raiz do projeto do fluxo de trabalho. Eles serão automaticamente adicionados para o `PATH` da execução do fluxo de trabalho.

Por exemplo, crie um arquivo chamado de `fastqc.sh` com o conteúdo a seguir:

```bash
#!/bin/bash
set -e
set -u

sample_id=${1}
reads=${2}

mkdir fastqc_${sample_id}_logs
fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
```

Salve-o, dê permissão de execução e mova-o para o diretório `bin` conforme mostrado abaixo:

```bash
chmod +x fastqc.sh
mkdir -p bin
mv fastqc.sh bin
```

Então, abra o arquivo `script7.nf` e substitua o script do processo `FASTQC` com o código a seguir:

```groovy
script:
"""
fastqc.sh "$sample_id" "$reads"
"""
```

Execute-o como anteriormente:

```bash
nextflow run script7.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

### :material-check-all: Resumo

Nessa etapa você aprendeu:

1. Como escrever ou usar scripts personalizados existentes em seu fluxo de trabalho do Nextflow.
2. Como evitar o uso de caminhos absolutos tendo seus scripts na pasta `bin/`.

## Métricas e relatórios

O Nextflow pode produzir vários relatórios e gráficos fornecendo várias métricas de tempo de execução e informações de execução.

Execute o fluxo de trabalho [rnaseq-nf](https://github.com/nextflow-io/rnaseq-nf) introduzido anteriormente, conforme mostrado abaixo:

```bash
nextflow run rnaseq-nf -with-docker -with-report -with-trace -with-timeline -with-dag dag.png
```

A opção `-with-docker` inicia cada tarefa da execução como um comando de execução de contêiner do Docker.

A opção `-with-report` permite a criação do relatório de execução do fluxo de trabalho. Abra o arquivo `report.html` com um navegador para ver o relatório criado com o comando acima.

A opção `-with-trace` permite a criação de um arquivo separado por tabulações (TSV) contendo informações de tempo de execução para cada tarefa executada. Verifique o `trace.txt` para um exemplo.

A opção `-with-timeline` permite a criação do relatório da linha do tempo do fluxo de trabalho mostrando como os processos foram executados ao longo do tempo. Isso pode ser útil para identificar as tarefas e gargalos que consomem mais tempo. Veja um exemplo [neste link](https://www.nextflow.io/docs/latest/tracing.html#timeline-report).

Por fim, a opção `-with-dag` permite a renderização da representação de grafo acíclico direcionado da execução do fluxo de trabalho. Nota: Este recurso requer a instalação do [Graphviz](http://www.graphviz.org/) em seu computador. Veja [aqui](https://www.nextflow.io/docs/latest/tracing.html#dag-visualisation) para mais detalhes. Então tente executar:

```bash
open dag.png
```

!!! warning

    As métricas de tempo de execução podem estar incompletas para execuções com tarefas com curto tempo de execução, como no caso deste tutorial.

!!! info

    Você visualiza os arquivos HTML clicando com o botão direito do mouse no nome do arquivo na barra lateral esquerda e escolhendo o item de menu **Show Preview**.

## Execute um projeto do GitHub

O Nextflow permite a execução de um projeto de fluxo de trabalho diretamente de um repositório do GitHub (ou serviços semelhantes, por exemplo, BitBucket e GitLab).

Isso simplifica o compartilhamento e implantação de projetos complexos e o rastreamento de mudanças de uma maneira consistente.

O repositório do GitHub a seguir hospeda uma versão completa do fluxo de trabalho apresentado neste tutorial: <https://github.com/nextflow-io/rnaseq-nf>

Você pode executá-lo especificando o nome do projeto e com isso iniciar a execução de cada tarefa como um comando de execução de contêiner do Docker:

```bash
nextflow run nextflow-io/rnaseq-nf -with-docker
```

Ele baixa automaticamente o contêiner e o armazena na pasta `$HOME/.nextflow`.

Use o comando `info` para mostrar as informações do projeto:

```bash
nextflow info nextflow-io/rnaseq-nf
```

O Nextflow permite a execução de uma revisão específica do seu projeto usando a opção de linha de comando `-r`. Por exemplo:

```bash
nextflow run nextflow-io/rnaseq-nf -r v2.1 -with-docker
```

As revisões são definidas usando etiquetas do Git ou ramos definidos no repositório do projeto.

As etiquetas permitem o controle preciso das alterações nos arquivos e dependências do projeto ao longo do tempo.

## Mais recursos

-   [Documentação do Nextflow](http://docs.nextflow.io) - A página inicial dos documentos do Nextflow.
-   [Nextflow patterns](https://github.com/nextflow-io/patterns) - Uma coleção de padrões de implementação do Nextflow.
-   [CalliNGS-NF](https://github.com/CRG-CNAG/CalliNGS-NF) - Um fluxo de trabalho de chamada de variante implementando as melhores práticas recomendadas do GATK.
-   [nf-core](http://nf-co.re/) - Uma coleção comunitária de fluxos de trabalho genômicos prontos para produção.
