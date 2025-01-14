---
title: Orientação
description: Como configurar um ambiente de desenvolvimento para executar Nextflow
---

# Orientação

O ambiente do Gitpod contem dados de teste que serão utilizados nesse treinamento.

!!! note

    Vá [para este link](../envsetup/index.pt.md) se você ainda não configurou seu ambiente no Gitpod.

## Começando

Você irá completar esse módulo na pasta `nf-training/`.

Nessa pasta você irá encontrar vários arquivos de dados (`ggal`, `index`, `meta`...) e também alguns scripts e arquivos de configuração.

```console
.
├── data
│   ├── ggal
│   │   └── <data files>
│   ├── index
│   │   └── <data files>
│   ├── meta
│   │   └── <data files>
│   ├── prots
│   │   └── <data files>
│   ├── reads
│   │   └── <data files>
│   └── test
│       └── <data files>
├── env.yml
├── hello.nf
├── hello_py.nf
├── modules.hello.nf
├── nextflow.config
├── script1.nf
├── script2.nf
├── script3.nf
├── script4.nf
├── script5.nf
├── script6.nf
├── script7.nf
└── snippet.nf
```

Cada arquivo será utilizado nesse treinamento.

## Escolhendo uma versão do Nextflow

Por padrão, o Nextflow irá trazer a última versão estável para seu ambiente.

No entanto, Nextflow vive em uma evolução constante na medida que melhorias são implementadas.

As últimas versões podem ser conferidas no GitHub, [aqui](https://github.com/nextflow-io/nextflow/releases).

Se você deseja utilizar uma versão específica do Nextflow, você pode configurar a variável `NXF_VER` como mostrado abaixo:

```bash
export NXF_VER=23.10.1
```

!!! question "Exercise"

    Abra o [ambiente de treinamento no Gitpod](https://gitpod.io/#https://github.com/nextflow-io/training) e use o seguinte comando para ir até a pasta `nf-customize`. Visualize os arquivos nessa pasta utilizando o comando `tree`:

    ```bash
    cd /workspace/gitpod/nf-training
    tree .
    ```

## Variáveis do ambiente

Por padrão, o Nextflow irá trazer a última versão estável para seu ambiente.

No entanto, Nextflow vive em uma evolução constante na medida que melhorias são implementadas.

As últimas versões podem ser conferidas no GitHub, [aqui](https://github.com/nextflow-io/nextflow/releases).

Se você deseja utilizar uma versão específica do Nextflow, você pode configurar a variável `NXF_VER` como mostrado abaixo:

```bash
export NXF_VER=23.10.1
```

!!! note

    Esse material requer uma versão igual ou posterior a `NXF_VER=23.10.1`.

Se você exportou a variável `NXF_VER` como acima, execute `nextflow -version` novamente para confirmar que suas mudanças foram aplicadas.
