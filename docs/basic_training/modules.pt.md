---
description: Material de treinamento básico do Nextflow
---

# Modularização

A definição de bibliotecas modulares simplifica a escrita de fluxos de trabalho complexos de análise de dados, além tornar o reuso de processos mais fácil.

Ao usar o exemplo `hello.nf` da seção de introdução, nós converteremos os processos do fluxo de trabalho em módulos e, em seguida, executaremos estes processos dentro do escopo `workflow` de diferentes formas.

## Módulos

A DSL2 do Nextflow permite a definição de scripts de módulos autônomos que podem ser incluídos e compartilhados em vários fluxos de trabalho. Cada módulo pode conter sua própria definição de `process` ou `workflow`.

### Importando módulos

Os componentes definidos no script do módulo podem ser importados para outros scripts do Nextflow usando a instrução `include`. Isso permite que você armazene esses componentes em arquivos separados para que possam ser reutilizados em vários fluxos de trabalho.

Usando o exemplo `hello.nf`, podemos fazer isso:

-   Criando um arquivo chamado `modules.nf` no mesmo diretório do `hello.nf`.
-   Copiando e colando as duas definições de processo para `SPLITLETTERS` e `CONVERTTOUPPER` em `modules.nf`.
-   Removendo as definições `process` no script `hello.nf`.
-   Importando os processos de `modules.nf` dentro do script `hello.nf` em qualquer lugar acima da definição de `workflow`:

```groovy linenums="1"
include { SPLITLETTERS } from './modules.nf'
include { CONVERTTOUPPER } from './modules.nf'
```

!!! note

    Em geral, você deve usar caminhos relativos para definir a localização dos scripts do módulo usando o prefixo `./`.

!!! exercise

    Crie um arquivo `modules.nf` com os processos previamente definidos no script `hello.nf`. Em seguida, remova esses processos de `hello.nf` e adicione as definições `include` mostradas acima.

    ??? solution

        O script `hello.nf` deve ser similar a este:

        ```groovy linenums="1"
        #!/usr/bin/env nextflow

        params.greeting  = 'Hello world!'
        greeting_ch = Channel.of(params.greeting)

        include { SPLITLETTERS   } from './modules.nf'
        include { CONVERTTOUPPER } from './modules.nf'

        workflow {
            letters_ch = SPLITLETTERS(greeting_ch)
            results_ch = CONVERTTOUPPER(letters_ch.flatten())
            results_ch.view { it }
        }
        ```

        Você deve ter o seguinte código em `./modules.nf`:

        ```groovy linenums="1"
        process SPLITLETTERS {
            input:
            val x

            output:
            path 'chunk_*'

            script:
            """
            printf '$x' | split -b 6 - chunk_
            """
        }

        process CONVERTTOUPPER {
            input:
            path y

            output:
            stdout

            script:
            """
            cat $y | tr '[a-z]' '[A-Z]'
            """
        }
        ```

        Agora nós modularizamos os processos, o que faz com que o código seja reutilizável.

### Importações múltiplas

Se um script de módulo Nextflow contiver várias definições de `process`, elas também podem ser importadas usando uma única instrução `include`, conforme mostrado no exemplo abaixo:

```groovy linenums="1"
include { SPLITLETTERS; CONVERTTOUPPER } from './modules.nf'
```

### Apelidos dos módulos

Ao incluir um componente de um módulo, é possível especificar um apelido para os processos usando a declaração `as`. Isso permite a inclusão e a invocação do mesmo componente várias vezes usando diferentes apelidos:

```groovy linenums="1"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'
greeting_ch = Channel.of(params.greeting)

include { SPLITLETTERS as SPLITLETTERS_one } from './modules.nf'
include { SPLITLETTERS as SPLITLETTERS_two } from './modules.nf'

include { CONVERTTOUPPER as CONVERTTOUPPER_one } from './modules.nf'
include { CONVERTTOUPPER as CONVERTTOUPPER_two } from './modules.nf'

workflow {
    letters_ch1 = SPLITLETTERS_one(greeting_ch)
    results_ch1 = CONVERTTOUPPER_one(letters_ch1.flatten())
    results_ch1.view { it }

    letters_ch2 = SPLITLETTERS_two(greeting_ch)
    results_ch2 = CONVERTTOUPPER_two(letters_ch2.flatten())
    results_ch2.view { it }
}
```

!!! exercise

    Salve o trecho anterior como `hello.2.nf`, e tente adivinhar qual saída será mostrada na tela.

    ??? solution

        A saída de `hello.2.nf` deve ser semelhante a essa:

        ```console title="Output"
        N E X T F L O W  ~  version 23.04.1
        Launching `hello.2.nf` [crazy_shirley] DSL2 - revision: 99f6b6e40e
        executor >  local (6)
        [2b/ec0395] process > SPLITLETTERS_one (1)   [100%] 1 of 1 ✔
        [d7/be3b77] process > CONVERTTOUPPER_one (1) [100%] 2 of 2 ✔
        [04/9ffc05] process > SPLITLETTERS_two (1)   [100%] 1 of 1 ✔
        [d9/91b029] process > CONVERTTOUPPER_two (2) [100%] 2 of 2 ✔
        WORLD!
        HELLO
        HELLO
        WORLD!
        ```

!!! tip

    Você pode armazenar cada processo em arquivos separados em subpastas separadas ou combinados em um arquivo grande (ambos são válidos).
    Você pode encontrar exemplos disso em repositórios públicos, como no [tutorial de RNA-Seq da Seqera](https://github.com/seqeralabs/rnaseq-nf/tree/master/modules) ou em fluxos de trabalho do nf-core, como o [nf-core/rnaseq](https://github.com/nf-core/rnaseq/tree/master/modules/nf-core).

## Definição de saída

O Nextflow permite o uso de definições de saída alternativas em fluxos de trabalho para simplificar seu código.

No exemplo básico anterior (`hello.nf`), definimos os nomes dos canais para especificar a entrada para o próximo processo:

```groovy linenums="1"
workflow  {
    greeting_ch = Channel.of(params.greeting)
    letters_ch = SPLITLETTERS(greeting_ch)
    results_ch = CONVERTTOUPPER(letters_ch.flatten())
    results_ch.view { it }
}
```

!!! note

    Nós movemos o `greeting_ch` para o escopo `workflow` para este exercício.

Também podemos definir explicitamente a saída de um canal para outro usando o atributo `.out`, removendo completamente as definições de canal:

```groovy linenums="1" hl_lines="3-5"
workflow  {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.view()
}
```

Se um processo define dois ou mais canais de saída, cada canal pode ser acessado indexando o atributo `.out`, por exemplo, `.out[0]`, `.out[1]`, etc. Em nosso exemplo, temos apenas a saída `[0]'th`:

```groovy linenums="1" hl_lines="5"
workflow  {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out[0].view()
}
```

Alternativamente, a definição de `output` do processo permite o uso da instrução `emit` para definir um identificador nomeado que pode ser usado para referenciar o canal no escopo externo.

Por exemplo, tente adicionar a instrução `emit` no processo `CONVERTTOUPPER` em seu arquivo `modules.nf`:

```groovy linenums="1" title="modules.nf"
process SPLITLETTERS {
    input:
    val x

    output:
    path 'chunk_*'

    script:
    """
    printf '$x' | split -b 6 - chunk_
    """
}

process CONVERTTOUPPER {
    input:
    path y

    output:
    stdout emit: upper

    script:
    """
    cat $y | tr '[a-z]' '[A-Z]'
    """
}
```

Em seguida, altere o escopo `workflow` em `hello.nf` para chamar essa saída nomeada específica (observe o `.upper` adicionado):

```groovy linenums="1" title="hello.nf"
workflow {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}
```

### Usando saídas canalizadas

Outra maneira de lidar com as saídas no escopo `workflow` é usar pipes `|`.

!!! exercise

     Tente alterar o script do fluxo de trabalho para o trecho abaixo:

    ```groovy linenums="1"
    workflow {
        Channel.of(params.greeting) | SPLITLETTERS | flatten | CONVERTTOUPPER | view
    }
    ```

     Aqui usamos um [pipe](https://www.nextflow.io/docs/latest/dsl2.html#pipes) que passa a saída de um processo como um canal para o próximo processo sem a necessidade de aplicar `.out` ao nome do processo.

## Definição do escopo workflow

O escopo `workflow` permite a definição de componentes que definem a invocação de um ou mais processos ou operadores:

```groovy linenums="1"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'

include { SPLITLETTERS } from './modules.nf'
include { CONVERTTOUPPER } from './modules.nf'


workflow meu_fluxo_de_trabalho {
    greeting_ch = Channel.of(params.greeting)
    SPLITLETTERS(greeting_ch)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}

workflow {
    meu_fluxo_de_trabalho()
}
```

Por exemplo, o trecho acima define um `workflow` chamado `meu_fluxo_de_trabalho`, que pode ser chamado por meio de outra definição de `workflow`.

!!! note

    Certifique-se de que seu arquivo `modules.nf` é o que contém o `emit` no processo `CONVERTTOUPPER`.

!!! warning

    Um componente de um fluxo de trabalho pode acessar qualquer variável ou parâmetro definido no escopo externo. No exemplo em execução, também podemos acessar `params.greeting` diretamente na definição de `workflow`.

### Entradas no escopo workflow

Um componente `workflow` pode declarar um ou mais canais de entrada usando a instrução `take`. Por exemplo:

```groovy linenums="1"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'

include { SPLITLETTERS } from './modules.nf'
include { CONVERTTOUPPER } from './modules.nf'

workflow meu_fluxo_de_trabalho {
    take:
    greeting

    main:
    SPLITLETTERS(greeting)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())
    CONVERTTOUPPER.out.upper.view { it }
}
```

!!! note

    Quando a instrução `take` é usada, a definição `workflow` precisa ser declarada dentro do bloco `main`.

A entrada para o `workflow` pode então ser especificada como um argumento:

```groovy linenums="1"
workflow {
    meu_fluxo_de_trabalho(Channel.of(params.greeting))
}
```

### Saídas no escopo workflow

Um bloco `workflow` pode declarar um ou mais canais de saída usando a instrução `emit`. Por exemplo:

```groovy linenums="1"
workflow meu_fluxo_de_trabalho {
    take:
    greeting

    main:
    SPLITLETTERS(greeting)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())

    emit:
    CONVERTTOUPPER.out.upper
}

workflow {
    meu_fluxo_de_trabalho(Channel.of(params.greeting))
    meu_fluxo_de_trabalho.out.view()
}
```

Como resultado, podemos usar a notação `meu_fluxo_de_trabalho.out` para acessar as saídas de `meu_fluxo_de_trabalho` na chamada `workflow`.

Também podemos declarar saídas nomeadas dentro do bloco `emit`.

```groovy linenums="1" hl_lines="10 15"
workflow meu_fluxo_de_trabalho {
    take:
    greeting

    main:
    SPLITLETTERS(greeting)
    CONVERTTOUPPER(SPLITLETTERS.out.flatten())

    emit:
    meus_dados = CONVERTTOUPPER.out.upper
}

workflow {
    meu_fluxo_de_trabalho(Channel.of(params.greeting))
    meu_fluxo_de_trabalho.out.meus_dados.view()
}
```

O resultado do trecho de código acima pode ser acessado usando `meu_fluxo_de_trabalho.out.meus_dados`.

### Chamando escopos workflows nomeados

Dentro de um script `main.nf` (chamado `hello.nf` em nosso exemplo), também podemos ter vários fluxos de trabalho. Nesse caso, podemos chamar um fluxo de trabalho específico ao executar o código. Para isso, usamos a chamada de ponto de entrada `-entry <nome_do_flux_de_trabalho>`.

O trecho a seguir tem dois fluxos de trabalho nomeados (`meu_fluxo_de_trabalho_um` e `meu_fluxo_de_trabalho_dois`):

```groovy linenums="1"
#!/usr/bin/env nextflow

params.greeting = 'Hello world!'

include { SPLITLETTERS as SPLITLETTERS_one } from './modules.nf'
include { SPLITLETTERS as SPLITLETTERS_two } from './modules.nf'

include { CONVERTTOUPPER as CONVERTTOUPPER_one } from './modules.nf'
include { CONVERTTOUPPER as CONVERTTOUPPER_two } from './modules.nf'


workflow meu_fluxo_de_trabalho_um {
    letras_canal1 = SPLITLETTERS_one(params.greeting)
    resultados_canal1 = CONVERTTOUPPER_one(letters_ch1.flatten())
    resultados_canal1.view { it }
}

workflow meu_fluxo_de_trabalho_dois {
    letras_canal2 = SPLITLETTERS_two(params.greeting)
    resultados_canal2 = CONVERTTOUPPER_two(letters_ch2.flatten())
    resultados_canal2.view { it }
}

workflow {
    meu_fluxo_de_trabalho_um(Channel.of(params.greeting))
    meu_fluxo_de_trabalho_dois(Channel.of(params.greeting))
}
```

Você pode escolher qual fluxo de trabalho é executado usando o sinalizador `entry`:

```bash
nextflow run hello.2.nf -entry meu_fluxo_de_trabalho_um
```

### Escopos de parâmetros

Um script de módulo pode definir um ou mais parâmetros ou funções personalizadas usando a mesma sintaxe de qualquer outro script Nextflow. Usando os exemplos mínimos abaixo:

```groovy linenums="1" title="Script do módulo (<code>./modules.nf</code>)"
params.foo = 'Hello'
params.bar = 'world!'

def DIGAOLA() {
    println "$params.foo $params.bar"
}

```

```groovy linenums="1" title="Script principal (<code>./hello.nf</code>)"
#!/usr/bin/env nextflow

params.foo = 'Hola'
params.bar = 'mundo!'

include { DIGAOLA } from './modules.nf'

workflow {
    DIGAOLA()
}
```

A execução de `hello.nf` deve imprimir:

```console
Hola mundo!
```

Como destacado acima, o script imprimirá `Hola mundo!` em vez de `Hello world!` porque os parâmetros herdados do contexto de inclusão são substituídos pelas definições no arquivo de script onde estão sendo incluídos.

!!! info

    Para evitar que sejam ignorados, os parâmetros do fluxo de trabalho devem ser definidos no início do script antes de qualquer declaração de inclusão.

A opção `addParams` pode ser usada para estender os parâmetros do módulo sem afetar o escopo externo. Por exemplo:

```groovy linenums="1"
#!/usr/bin/env nextflow

params.foo = 'Hola'
params.bar = 'mundo!'

include { DIGAOLA } from './modules.nf' addParams(foo: 'Olá')

workflow {
    DIGAOLA()
}
```

A execução do script principal acima deve imprimir:

```console
Olá mundo!
```

## Notas de migração DSL2

Para visualizar um resumo das alterações introduzidas quando o Nextflow migrou da DSL1 para a DSL2, consulte as [notas de migração da DSL2](https://www.nextflow.io/docs/latest/dsl2.html#dsl2-migration-notes) na documentação oficial do Nextflow.
