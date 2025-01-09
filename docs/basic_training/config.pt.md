---
title: Configuração
description: Material de treinamento básico do Nextflow
---

# Configuração do Nextflow

Um recurso importante do Nextflow é a capacidade de desacoplar a implementação do fluxo de trabalho e as configurações exigidas pela plataforma onde ele será executado.

Isso permite a portabilidade da aplicação sem a necessidade de modificar seu código quando se faz necessária a execução em diferentes ambientes.

## Arquivo de configuração

Quando um script de fluxo de trabalho é executado, o Nextflow procura um arquivo chamado `nextflow.config` no diretório atual e no diretório base do script (se não for o mesmo que o diretório atual). Caso não encontre, o Nextflow verifica o arquivo: `$HOME/.nextflow/config`.

Quando existir mais de um dos arquivos acima, eles serão mesclados, de modo que as configurações do primeiro substituam as mesmas configurações que podem aparecer no segundo e assim por diante.

O mecanismo de pesquisa padrão do arquivo de configuração pode ser estendido fornecendo um arquivo de configuração extra usando a opção de linha de comando: `-c <arquivo de configuração>`.

### Sintaxe do arquivo de configuração

Um arquivo de configuração do Nextflow é um arquivo de texto simples contendo um conjunto de propriedades definidas usando a sintaxe:

```groovy linenums="1"
nome = valor
```

!!! info

     Observe que *strings* precisam ser colocadas entre aspas, enquanto números e valores booleanos (`true`, `false`) não. Além disso, observe que os valores são tipados, o que significa, por exemplo, que `1` é diferente de `'1'`, pois o primeiro é interpretado como o número um, enquanto o último é interpretado como uma *string*.

### Variáveis de configuração

As propriedades de configuração podem ser usadas como variáveis no próprio arquivo de configuração, usando a sintaxe usual `$nomePropriedade` ou `${expressao}`.

```groovy linenums="1"
propriedadeUm = 'mundo'
umaOutraPropriedade = "Olá $propriedadeUm"
caminhoCustomizado = "$PATH:/pasta/da/minha/app"
```

!!! tip

     No arquivo de configuração é possível acessar qualquer variável definida no ambiente de execução, como `$PATH`, `$HOME`, `$PWD`, etc.

### Comentários no arquivo de configuração

Os arquivos de configuração usam as mesmas convenções para comentários usados no script Nextflow:

```groovy linenums="1"
// comentar uma única linha

/*
    um comentário abrangendo
    várias linhas
  */
```

### Escopos de configuração

As definições de configuração podem ser organizadas em diferentes escopos. Pode-se utilizar a notação `escopo.propriedade` ou agrupar as propriedades no mesmo escopo usando a notação de chaves, como mostrado a seguir:

```groovy linenums="1"
alfa.x = 1
alfa.y = 'valor da string..'

beta {
    p = 2
    q = 'outra string ..'
}
```

### Configurar parâmetros

O escopo `params` permite a definição de parâmetros que substituem os valores definidos no script principal do fluxo de trabalho.

Isso é útil para reforçar o uso de um ou mais parâmetros de execução em um arquivo separado.

```groovy linenums="1" title="Arquivo de configuração"
params.foo = 'Bonjour'
params.bar = 'le monde!'
```

```groovy linenums="1" title="Script do fluxo de trabalho"
params.foo = 'Olá'
params.bar = 'mundo!'

// imprime ambos os parâmetros
println "$params.foo $params.bar"
```

!!! exercise

    Salve o primeiro trecho como `nextflow.config` e o segundo como `params.nf`. Em seguida, execute:

    ```bash
    nextflow run params.nf
    ```

    ??? Solution

        ```console
        Bonjour le monde!
        ```

    Execute novamente o comando anterior especificando o parâmetro `foo` na linha de comando:

    ```bash
    nextflow run params.nf --foo Olá
    ```

    ??? Solution

        ```console
        Olá le monde!
        ```

    Compare o resultado das duas execuções.

### Configurar ambiente

O escopo `env` permite a definição de uma ou mais variáveis que serão exportadas para o ambiente onde serão executadas as tarefas do fluxo de trabalho.

```groovy linenums="1"
env.ALFA = 'algum valor'
env.BETA = "$HOME/algum/caminho"
```

Salve o trecho acima como um arquivo chamado `meu-env.config`. Em seguida, salve o trecho abaixo em um arquivo chamado `foo.nf`:

```groovy linenums="1"
process FOO {
    debug true

    script:
    '''
    env | egrep 'ALFA|BETA'
    '''
}

workflow {
    FOO()
}
```

Por fim, execute o seguinte comando:

```bash
nextflow run foo.nf -c meu-env.config
```

??? Solution

    ```console
    BETA=/home/usuario/algum/caminho
    ALFA=algum valor
    ```

### Configurar processos

As [diretivas](https://www.nextflow.io/docs/latest/process.html#directives) de processos permite a especificação de configurações para a execução de uma tarefa, como `cpus`, `memory`, `container`, além de outros recursos, no script do fluxo de trabalho.

Isso é útil ao criarmos um exemplo-teste ou um protótipo para o nosso fluxo de trabalho.

No entanto, é sempre uma boa prática desassociar a lógica de execução do fluxo de trabalho das configurações que serão utilizadas por ele. Assim, é altamente recomendável definir as configurações do processo no arquivo de configuração do fluxo de trabalho em vez de no script do fluxo de trabalho.

Além disso, quaisquer [diretivas](https://www.nextflow.io/docs/latest/process.html#directives) do escopo dos processos (`process`) podem ser usadas no arquivo de configuração.

```groovy linenums="1"
process {
    cpus = 10
    memory = 8.GB
    container = 'biocontainers/bamtools:v2.4.0_cv3'
}
```

O trecho de configuração acima define as diretivas `cpus`, `memory` e `container` para todos os processos em seu fluxo de trabalho.

O [seletor de processo](https://www.nextflow.io/docs/latest/config.html#process-selectors) pode ser usado para aplicar a configuração a um processo específico ou grupo de processos (discutido posteriormente).

!!! info

     As unidades de memória e a duração de tempo podem ser especificadas usando uma notação baseada em string na qual o(s) dígito(s) e a unidade **podem** ser separados por um espaço em branco. Também pode-se usar a notação numérica na qual o(s) dígito(s) e a(s) unidade(s) são separados por um ponto e não são colocados entre aspas.

| Sintaxe de string | Sintaxe numérica | Valor                |
| ----------------- | ---------------- | -------------------- |
| `'10 KB'`         | `10.KB`          | 10240 bytes          |
| `'500 MB'`        | `500.MB`         | 524288000 bytes      |
| `'1 min'`         | `1.min`          | 60 segundos          |
| `'1 hour 25 sec'` | \-               | 1 hora e 25 segundos |

A sintaxe para definir as diretivas de processo no arquivo de configuração requer `=` (ou seja, operador de atribuição). Esta notação não deve ser usada para definir as diretivas do processo no script do fluxo de trabalho.

??? example

    ```groovy linenums="1"
    process FOO {
        cpus 4
        memory 2.GB
        time 1.hour
        maxRetries 3

        script:
        """
        seu_comando --cpus $task.cpus --mem $task.memory
        """
    }
    ```

Isso é especialmente importante quando você deseja criar uma definição de configuração usando uma expressão dinâmica com uma clausura. Por exemplo, em um arquivo de fluxo de trabalho:

```groovy linenums="1"
process FOO {
    memory { 4.GB * task.cpus }
}
```

E o equivalente em um arquivo de configuração, se você preferir configurar isso lá:

```groovy linenums="1"
process {
    withName: FOO {
        memory = { 4.GB * task.cpus }
    }
}
```

Diretivas que exigem mais de um valor, como a diretiva [pod](https://www.nextflow.io/docs/latest/process.html#pod), precisam ser expressas como um objeto Map no arquivo de configuração.

```groovy linenums="1"
process {
    pod = [ambiente: 'FOO', valor: '123']
}
```

Por fim, as diretivas que devem ser repetidas na definição do processo e nos arquivos de configuração precisam ser definidas como um objeto List. Por exemplo:

```groovy linenums="1"
process {
    pod = [[ambiente: 'FOO', valor: '123'],
           [ambiente: 'BAR', valor: '456']]
}
```

### Configurar execução do Docker

A imagem do contêiner a ser utilizada para a execução do processo pode ser especificada no arquivo `nextflow.config`:

```groovy linenums="1"
process.container = 'nextflow/rnaseq-nf'
docker.enabled = true
```

O uso de IDs únicos com "SHA256" para imagens Docker garante que o conteúdo da imagem não mude com o tempo, por exemplo:

```groovy linenums="1"
process.container = 'nextflow/rnaseq-nf@sha256:aeacbd7ea1154f263cda972a96920fb228b2033544c2641476350b9317dab266'
docker.enabled = true
```

### Configurar execução do Singularity

Para rodar um fluxo de trabalho com Singularity, é necessário fornecer o caminho para o arquivo de imagem do contêiner usando a diretiva de contêiner (`container`):

```groovy linenums="1"
process.container = '/alguma/imagem/singularity/imagem.sif'
singularity.enabled = true
```

!!! info

     O arquivo de imagem do contêiner deve ser um caminho absoluto: deve começar com `/`.

Os seguintes protocolos são suportados:

-   `library://` baixe a imagem do contêiner do [Singularity Library service](https://cloud.sylabs.io/library).
-   `shub://` baixe a imagem do contêiner do [Singularity Hub](https://singularity-hub.org/).
-   `docker://` baixe a imagem do contêiner do [Docker Hub](https://hub.docker.com/) e a converta para o formato Singularity.
-   `docker-daemon://` extraia a imagem do contêiner de uma instalação local do Docker e a converta em um arquivo de imagem Singularity.

!!! tip

     O hub do Singularity `shub://` não está mais disponível como serviço de construção de contêineres. Entretanto, as imagens existentes anteriores a 19 de abril de 2021 ainda funcionam.

!!! tip

     Ao especificar um nome simples de imagem de contêiner do Docker, o Nextflow faz o download e a converte implicitamente em uma imagem do Singularity quando a execução do Singularity está habilitada.

     ```groovy linenums="1"
     process.container = 'nextflow/rnaseq-nf'
     singularity.enabled = true
     ```

     A configuração acima instrui o Nextflow a usar o mecanismo Singularity para executar seus processos. O contêiner é extraído do repositório de imagens do Docker e armazenado em cache no diretório atual para ser usado em outras execuções.

     Como alternativa, se você tiver uma imagem Singularity, seu caminho absoluto pode ser especificado por meio do nome do contêiner usando a opção `-with-singularity` ou a configuração `process.container` no arquivo de configuração.

!!! exercise

     Tente executar o script conforme mostrado abaixo, alterando o arquivo `nextflow.config` para ser usado com o Singularity:

    ```bash
    nextflow run script7.nf
    ```

    !!! note

        O Nextflow irá baixar a imagem do contêiner automaticamente. Isto levará alguns segundos, dependendo da velocidade da sua conexão.

### Configurar execução com ambientes Conda

Ambientes Conda também podem ser fornecidos no arquivo de configuração. Basta adicionar a seguinte configuração no arquivo `nextflow.config`:

```groovy linenums="1"
process.conda = "/home/ubuntu/miniconda2/envs/nf-tutorial"
```

Você pode especificar o caminho de um ambiente Conda existente como **diretório** ou o caminho do arquivo YAML do ambiente Conda.
