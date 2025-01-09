# Orientação

O ambiente Gitpod contém todo o software, código e dados necessários para este curso. Você não precisa instalar nada por conta própria. No entanto, é necessária uma conta (gratuita) para logar - e recomendamos que você reserve alguns minutos para se familiarizar com a interface.

Caso ainda não tenha feito isso, siga [este link](../../envsetup/) antes de prosseguir.

## Materiais fornecidos

Ao longo deste curso, trabalharemos no diretório `hello-nextflow/`, que é carregado por padrão quando você abre o ambiente de trabalho do Gitpod. Este diretório contém todos os arquivos de código, dados de teste e arquivos auxiliares que você precisará.

Sinta-se à vontade para explorar o conteúdo deste diretório; a maneira mais fácil de fazer isso é usando o explorador de arquivos no lado esquerdo do ambiente de trabalho do Gitpod. Alternativamente, você pode usar o comando `tree`. Ao longo do curso, usamos a saída do `tree` para representar a estrutura e o conteúdo do diretório de forma legível - às vezes com pequenas modificações para maior clareza.

Aqui, geramos um índice até o segundo nível:

```bash
tree . -L 2
```

Se você executar isso dentro do diretório `hello-nextflow`, verá a seguinte saída:

```console title="Directory contents"
.
├── containers
│   ├── build
│   ├── data
│   ├── results
│   └── scripts
├── data
│   ├── bam
│   ├── greetings.csv
│   ├── ref
│   ├── sample_bams.txt
│   └── samplesheet.csv
├── hello-config
│   ├── demo-params.json
│   ├── main.nf
│   └── nextflow.config
├── hello-containers.nf
├── hello-genomics.nf
├── hello-modules
│   ├── demo-params.json
│   ├── main.nf
│   └── nextflow.config
├── hello-nf-core
│   ├── data
│   └── solution
├── hello-nf-test
│   ├── demo-params.json
│   ├── main.nf
│   ├── modules
│   └── nextflow.config
├── hello-operators.nf
├── hello-world.nf
├── nextflow.config
└── solutions
    ├── hello-config
    ├── hello-genomics
    ├── hello-modules
    ├── hello-nf-test
    ├── hello-operators
    └── hello-world

18 directories, 17 files
```

!!!nota

    Não se preocupe se isso parecer muita informação até o momento. Nós passaremos pelas partes relevantes ao longo das etapas do curso. Isso é apenas para te dar uma visão geral.

**Aqui está um resumo do que você deveria saber para começar:**

-   **Os arquivos `.nf`** são _scripts_ de fluxo de trabalho nomeados com base na parte do curso em que são utilizados.

-   **Os diretórios `hello-*`** são usados nas partes posteriores do curso, onde trabalhamos com mais de um arquivo de fluxo de trabalho.

-   **O arquivo `nextflow.config`** é um arquivo de configuração que define propriedades mínimas do ambiente. Você pode ignorá-lo por enquanto.

-   **O diretório `data`** contém os dados de entrada que usaremos na maior parte do curso. O conjunto de dados é descrito em detalhe na Parte 3, quando o introduzimos pela primeira vez.

-   **O diretório `solutions`** contém os _scripts_ de fluxo de trabalho completos resultantes de cada etapa do curso. Eles servem como referência para verificar seu trabalho e solucionar quaisquer problemas. As informações de nome e o número presentes no nome do arquivo correspondem à etapa da parte relevante do curso. Por exemplo, o arquivo `hello-world-4.nf` é o resultado esperado ao completar as etapas 1 a 4 da Parte 1: Hello World.

!!!dica

    Se, por algum motivo, você sair deste diretório, sempre poderá executar este comando para retornar:

    ```bash
    cd /workspace/gitpod/hello-nextflow
    ```

Agora, para iniciar o curso, clique na seta no canto inferior direito desta página.
