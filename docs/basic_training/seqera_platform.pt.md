---
title: Seqera Platform
description: Comece a usar a Seqera Platform
---

# Comece a usar a Seqera Platform

## Conceitos Básicos

A Seqera Platform, conhecida anteriormente como Nextflow Tower, é o posto de comando centralizado para gerenciamento de dados e fluxos de trabalho. Ele traz monitoramento, gerenciamento de logs e observabilidade para fluxos de trabalho distribuídos e simplifica a implantação de fluxos de trabalho em qualquer nuvem, cluster ou laptop. Na terminologia da Seqera Platform, um fluxo de trabalho é o que temos trabalhado até agora, e os pipelines são fluxos de trabalho pré-configurados que podem ser usados por todos os usuários em um espaço de trabalho. Ele é composto por um repositório de fluxo de trabalho, parâmetros de inicialização e um ambiente de computação. Vamos nos ater a essas definições nesta seção.

Os principais recursos da Seqera Platform incluem:

-   O lançamento de pipelines pré-configurados com facilidade.
-   Integração programática para atender às necessidades de uma organização.
-   Disponibilização pipelines em áreas de trabalho compartilhadas.
-   Gerenciamento da infraestrutura necessária para executar análise de dados em escala.

!!! tip

    [Registre-se](https://cloud.tower.nf/) para experimentar a Seqera Platform gratuitamente ou solicitar uma [demonstração](https://seqera.io/demo/) para implantações em seu próprio ambiente local ou na nuvem.

## Como usar

Você pode usar a Seqera Platform por meio da opção `-with-tower` ao usar o comando `nextflow run`, por meio da **interface gráfica online** ou da **API**.

### Com o comando `nextflow run`

Crie uma conta e faça login na Seqera Platform.

**1. Crie um novo token**

Você pode acessar seus tokens no menu suspenso **Settings**:

![Criar um token](img/usage_create_token.png)

**2. Dê um nome para seu token**

![Dê um nome para seu token](img/usage_name_token.png)

**3. Salve seu token com segurança**

Copie e guarde seu novo token em um local seguro.

![Salve o seu token](img/usage_token.png)

**4. Exporte seu token**

Uma vez que seu token foi criado, abra um terminal e digite:

```bash
export TOWER_ACCESS_TOKEN=eyxxxxxxxxxxxxxxxQ1ZTE=
```

Onde `eyxxxxxxxxxxxxxxxQ1ZTE=` é o token que você acabou de criar.

!!! note

    Verifique seu `nextflow -version`. Os tokens de portador requerem ao menos a versão 20.10.0 do Nextflow ou versões posteriores e isso pode ser configurado com o segundo comando mostrado acima. Você pode alterar para uma outra versão, se necessário.

Para enviar um pipeline para uma [área de trabalho](https://help.tower.nf/getting-started/workspace/) (workspace) usando a ferramenta de linha de comando do Nextflow, adicione o ID da área de trabalho em seu ambiente. Por exemplo:

```bash
export TOWER_WORKSPACE_ID=000000000000000
```

O ID da área de trabalho pode ser encontrado na página de visão geral das áreas de trabalho (workspaces) da organização.

**5. Execute o Nextflow com a Seqera Platform**

Execute normalmente seus fluxos de trabalho do Nextflow com a adição do comando `-with-tower`:

```bash
nextflow run hello.nf -with-tower
```

Você verá e poderá monitorar suas **tarefas do Nextflow** na Seqera Platform.

Para configurar e executar tarefas do Nextflow em **ambientes na nuvem**, visite a [seção de ambientes de computação](https://help.tower.nf/compute-envs/overview/) (compute environments).

!!! exercise

    Execute o script de RNA-Seq `script7.nf` usando o sinalizador `-with-tower`, depois de concluir corretamente as configurações de token descritas acima.

    ??? tip

        Vá para <https://tower.nf/>, faça o login, em seguida, clique na guia de execuções (Run) e selecione a execução que você acabou de enviar. Se você não conseguir encontrá-la, verifique novamente se seu token foi adicionado corretamente ao ambiente.

### Com uma interface gráfica online

Para executar usando a interface gráfica (GUI), existem três etapas principais:

1. Crie uma conta e faça login na Seqera Platform, disponível gratuitamente, em [tower.nf](https://tower.nf).
2. Crie e configure um novo [ambiente de computação](https://help.tower.nf/compute-envs/overview/) (compute environment).
3. Comece a [lançar pipelines](https://help.tower.nf/launch/launchpad/).

#### Configurando seu ambiente de computação

A Seqera Platform usa o conceito de **Ambientes de Computação** (compute environments) para definir a plataforma de execução onde um fluxo de trabalho será executado.

Ele suporta o lançamento de fluxos de trabalho em um número crescente de infraestruturas de **nuvem** e **on-prem** (infraestrutura dedicada).

![Ambientes de computação](img/compute_env_platforms.png)

Cada ambiente de computação deve ser pré-configurado para permitir que a Seqera Platform envie tarefas. Você pode ler mais sobre como configurar cada ambiente usando os links abaixo.

!!! tip "Os guias a seguir descrevem como configurar cada um desses ambientes de computação."

    * [AWS Batch](https://help.tower.nf/compute-envs/aws-batch/)
    * [Azure Batch](https://help.tower.nf/compute-envs/azure-batch/)
    * [Google Cloud](https://help.tower.nf/compute-envs/google-cloud/)
    * [Google Batch](https://help.tower.nf/compute-envs/google-cloud-batch/)
    * [Google Life Sciences](https://help.tower.nf/compute-envs/google-cloud-lifesciences/)
    * [IBM LSF](https://help.tower.nf/compute-envs/lsf/)
    * [Slurm](https://help.tower.nf/compute-envs/slurm/)
    * [Grid Engine](https://help.tower.nf/compute-envs/altair-grid-engine/)
    * [Altair PBS Pro](https://help.tower.nf/compute-envs/altair-pbs-pro/)
    * [Amazon Kubernetes (EKS)](https://help.tower.nf/compute-envs/eks/)
    * [Google Kubernetes (GKE)](https://help.tower.nf/compute-envs/gke/)
    * [Hosted Kubernetes](https://help.tower.nf/compute-envs/k8s/)

#### Selecionando um ambiente de computação padrão

Se você tiver mais de um **Ambiente de computação**, poderá selecionar qual deles será usado por padrão ao lançar um pipeline.

1. Navegue até os seus [ambientes de computação](https://help.tower.nf/compute-envs/overview/).
2. Escolha seu ambiente padrão selecionando o botão **Make primary**.

**Parabéns!**

Agora você está pronto para lançar fluxos de trabalho com seu ambiente de computação principal.

#### Launchpad

O Launchpad torna fácil para qualquer usuário da área de trabalho lançar um pipeline pré-configurado.

![Launchpad](img/overview_launch.png)

Um pipeline é um repositório que contém um fluxo de trabalho do Nextflow, um ambiente de computação e parâmetros de fluxo de trabalho.

#### Formulário de Parâmetros de Pipeline

O Launchpad detecta automaticamente a presença de um `nextflow_schema.json` na raiz do repositório e cria dinamicamente um formulário onde os usuários podem facilmente atualizar os parâmetros.

!!! info

    A exibição de formulários de parâmetro aparecerá se o pipeline tiver um arquivo de esquema do Nextflow para os parâmetros. Consulte o [Guia do esquema do Nextflow](https://help.tower.nf/workflow-schema/overview) para saber mais sobre os casos de uso do arquivo de esquema e como criá-los.

Isso torna trivial para usuários sem experiência em Nextflow inserir seus parâmetros de fluxo de trabalho e lançá-lo.

![Pipeline parameters](img/launch_rnaseq_nextflow_schema.png)

#### Adicionando um novo pipeline

A adição de um pipeline ao launchpad da área de trabalho é detalhada na íntegra na [documentação da Seqera Platform](https://help.tower.nf/launch/launch/).

Em resumo, essas são as etapas que você precisa seguir para configurar um pipeline.

1. Selecione o botão Launchpad na barra de navegação. Isso abrirá o **Formulário de inicialização**.
2. Selecione um [ambiente de computação](https://help.tower.nf/compute-envs/overview).
3. Insira o repositório do fluxo de trabalho que você deseja iniciar. e.g. <https://github.com/nf-core/rnaseq.git>
4. Selecione um **número de revisão** para o fluxo de trabalho. O branching padrão do Git (main/master) ou `manifest.defaultBranch` na configuração do Nextflow será usada por padrão.
5. Defina o local do **diretório de trabalho** (`workDir`) do Nextflow. O local associado ao ambiente de computação será selecionado por padrão.
6. Digite o(s) nome(s) de cada um dos **perfis de configuração** do Nextflow seguido da tecla `enter`. Veja mais [na documentação oficial](https://www.nextflow.io/docs/latest/config.html#config-profiles) sobre a configuração de perfis.
7. Insira quaisquer parâmetros do fluxo de trabalho no formato YAML ou JSON. Exemplo com YAML:

    ```yaml
    leituras: "s3://nf-bucket/exome-data/ERR013140_{1,2}.fastq.bz2"
    pares_de_leituras: true
    ```

8. Selecione Launch para iniciar a execução do pipeline.

!!! info

    Os fluxos de trabalho do Nextflow são simplesmente repositórios Git e podem ser alterados para qualquer plataforma de hospedagem Git pública ou privada. Consulte [Integração com o Git](https://help.tower.nf/git/overview/) nos documentos da Seqera Platform e [Compartilhamento de Pipelines](https://www.nextflow.io/docs/latest/sharing.html) na documentação do Nextflow para obter mais detalhes.

!!! note

    As credenciais associadas ao ambiente de computação devem ser capazes de acessar o diretório de trabalho.

!!! info

    Na configuração, o caminho completo para um bucket deve ser especificado com aspas simples em torno de strings e sem aspas em booleanas ou números.

!!! tip

    Para criar seu próprio esquema de Nextflow personalizado para seu fluxo de trabalho, veja os exemplos dos fluxos de trabalho do `nf-core` que adotaram essa abordagem. Por exemplo, o [eager](https://github.com/nf-core/eager/blob/2.3.3/nextflow_schema.json) e o [rnaseq](https://github.com/nf-core/rnaseq/blob/3.0/nextflow_schema.json).

Para opções de configurações avançadas, confira essa [página](https://help.tower.nf/launch/advanced/).

Também há suporte da comunidade disponível se você tiver problemas, junte-se ao Slack do Nextflow seguindo este [link](https://www.nextflow.io/slack-invite.html).

### API

Para saber mais sobre como usar a API da Seqera Platform, visite a [seção da API](https://help.tower.nf/api/overview/) na documentação.

## Áreas de trabalho e Organizações

A Seqera Platform simplifica o desenvolvimento e a execução de pipelines, fornecendo uma interface centralizada para usuários e organizações.

Cada usuário tem uma **área de trabalho** exclusiva onde pode interagir e gerenciar todos os recursos, como fluxos de trabalho, ambientes de computação e credenciais. Detalhes disso podem ser encontrados [aqui](https://help.tower.nf/getting-started/workspace/).

As organizações podem ter vários espaços de trabalho com acesso personalizado para **membros** e **colaboradores** específicos da organização.

### Recursos de organização

Você pode criar sua própria organização e área de trabalho de participante seguindo a documentação [aqui](https://help.tower.nf/orgs-and-teams/workspace-management/).

A Seqera Platform permite a criação de várias organizações, cada uma das quais pode conter várias áreas de trabalho com usuários e recursos compartilhados. Isso permite que qualquer organização personalize e organize o uso de recursos enquanto mantém uma camada de controle de acesso para usuários associados a uma área de trabalho.

### Usuários da organização

Qualquer usuário pode ser adicionado ou removido de uma determinada organização ou área de trabalho e pode receber um papel de acesso específico dentro dessa área de trabalho.

O recurso Equipes fornece uma maneira para as organizações agruparem vários usuários e participantes em equipes. Por exemplo, `desenvolvedores-fluxos de trabalho` ou `analistas`, e aplicar controle de acesso a todos os usuários dentro desta equipe coletivamente.

Para mais informações, consulte a seção de [Gerenciamento de Usuário](https://help.tower.nf/orgs-and-teams/organizations/).

#### Configurando uma nova organização

As organizações são a estrutura de nível mais alto e contêm áreas de trabalho, membros, equipes e colaboradores.

Para criar uma nova Organização:

1.  Clique no menu suspenso ao lado do seu nome e selecione New organization para abrir a caixa de diálogo de criação.
2.  Na caixa de diálogo, preencha os campos de acordo com sua organização. Os campos Name e Full name são obrigatórios.

    !!! note

        Um nome válido para a organização deve seguir um padrão específico. Consulte a interface de usuário para obter mais instruções.

3.  O restante dos campos, como Description, Location, Website URL e logo URL, são opcionais.
4.  Depois que os detalhes forem preenchidos, você poderá acessar a organização recém-criada usando a página da organização, que lista todas as suas organizações.

    !!! note

        É possível alterar os valores dos campos opcionais usando a opção Edit na página da organização ou usando a guia Settings na página da organização, desde que você seja o Proprietário (Owner) da organização.

    !!! tip

        Uma lista de todos os Membros, Equipes e Colaboradores incluídos pode ser encontrada na página da organização.
