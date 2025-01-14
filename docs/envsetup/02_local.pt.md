# Instalação local

Se você **não conseguiu** acessar o Gitpod, uma alternativa é instalar tudo localmente.

Alguns dos requisitos podem ser diferentes, a depender da sua máquina local.

## Requisitos

Nextflow pode ser utilizado em qualquer sistema compatível com o POSIX (Linux, macOS, Subsistema Linux para Windows, etc.).

**Requisitos**

- Bash
- [Java 11 (ou posterior, até o 21)](https://www.oracle.com/technetwork/java/javase/downloads/index.html)
- [Git](https://git-scm.com/)
- [Docker](https://docs.docker.com/get-docker/)

**Requisitos opcionais**

- [Singularity](https://github.com/sylabs/singularity) 2.5.x (ou posterior)
- [Conda](https://conda.io/) 4.5 (ou posterior)
- [Graphviz](http://www.graphviz.org/)
- [AWS CLI](https://aws.amazon.com/cli/)
- Um ambiente computacional configurado no AWS Batch

## Baixando Nextflow

Execute esse comando em seu terminal:

```bash
wget -qO- https://get.nextflow.io | bash
```

Você também pode usar o comando `curl`:

```bash
curl -s https://get.nextflow.io | bash
```

Em seguida, garanta que o binário baixado é executável:

```bash
chmod +x nextflow
```

Por fim, garanta que o executável do `nextflow` está na sua `$PATH`. O executável pode estar presente em `/usr/local/bin`, `/bin/`, etc.

## Docker

Garanta que o Docker Desktop está rodando em sua máquina. Você pode baixar o Docker [aqui](https://docs.docker.com/get-docker/).

## Material de treinamento

Você pode ver o material de treinamento [aqui](https://training.nextflow.io/).

Para baixar o material, execute esse comando:

```bash
git clone https://github.com/nextflow-io/training.git
```

Então use `cd` para entrar no diretório `nf-training`.

## Verificando sua instalação

Verifique que você instalou `nextflow` corretamente executando o seguinte comando:

```bash
nextflow info
```

Esse comando deve imprimir a versão, o sistema e o ambiente de execução atuais.

!!! question "Exercise"

    Para testar que seu ambiente está funcionando corretamente, execute o seguinte comando:

    ```bash
    nextflow info
    ```

    Esse comando deve trazer informação sobre a versão do Nextflow e sobre seu ambiente de execução:

    ```console
    Version: 23.10.1 build 5891
    Created: 12-01-2024 22:01 UTC
    System: Linux 6.1.75-060175-generic
    Runtime: Groovy 3.0.19 on OpenJDK 64-Bit Server VM 11.0.1-internal+0-adhoc..src
    Encoding: UTF-8 (UTF-8)
    ```
