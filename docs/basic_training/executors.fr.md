---
description: Atelier de formation de base sur Nextflow
---

# Scénarios de déploiement

Les applications génomiques du monde réel peuvent engendrer l'exécution de milliers de tâches. Dans ce scénario, un planificateur de lots est généralement utilisé pour déployer un workflow dans un cluster informatique, permettant l'exécution de nombreuses tâches en parallèle sur de nombreux nœuds informatiques.

Nextflow a un support intégré pour les plannificateurs batch les plus couramment utilisés, tels que Univa Grid Engine, [SLURM](https://slurm.schedmd.com/) et IBM LSF. Consultez la documentation de Nextflow pour obtenir la liste complète des prises en charge [plates-formes d'exécution](https://www.nextflow.io/docs/latest/executor.html).

## Déploiement du cluster

L'une des principales caractéristiques de Nextflow est la capacité de découpler la mise en œuvre du workflow de la plate-forme d'exécution proprement dite. La mise en œuvre d'une couche d'abstraction permet de déployer le workflow résultant sur n'importe quelle plate-forme d'exécution prise en charge par le cadre.

![Executeurs Nextflow](img/nf-executors.png)

Pour exécuter votre workflow avec un planificateur batch, modifiez le fichier `nextflow.config` en spécifiant l'exécuteur cible et les ressources informatiques requises si nécessaire. Par exemple, le fichier `nextflow.config` peut être modifié :

```groovy linenums="1"
process.executor = 'slurm'
```

## Gestion des ressources du cluster

Lors de l'utilisation d'un planificateur batch, il est souvent nécessaire de spécifier le nombre de ressources (cpus, mémoire, temps d'exécution, etc.) requises par chaque tâche.

Pour ce faire, il convient d'utiliser les directives de processus suivantes :

|                                                                    |                                                                        |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| [queue](https://www.nextflow.io/docs/latest/process.html#queue)    | la _queue_ de cluster à utiliser pour le calcul                        |
| [cpus](https://www.nextflow.io/docs/latest/process.html#cpus)      | le nombre de _cpus_ à allouer pour l'exécution d'une tâche             |
| [memoire](https://www.nextflow.io/docs/latest/process.html#memory) | la quantité de mémoire à allouer pour l'exécution d'une tâche          |
| [temps](https://www.nextflow.io/docs/latest/process.html#time)     | la quantité maximale de _temps_ à allouer pour l'exécution d'une tâche |
| [disque](https://www.nextflow.io/docs/latest/process.html#disk)    | la quantité de mémoire _disk_ requise pour l'exécution d'une tâche     |

### Ressources à l'échelle du workflow

Utilisez le champ d'application `process` pour définir les besoins en ressources de tous les processus de vos applications de workflow. Par exemple :

```groovy linenums="1"
process {
    executor = 'slurm'
    queue = 'short'
    memory = '10 GB'
    time = '30 min'
    cpus = 4
}
```

### Soumettre Nextflow en tant que tache

Bien que la commande principale de Nextflow puisse être lancée sur le nœud de connexion / tête d'un cluster, il faut savoir que le nœud doit être configuré pour des commandes qui s'exécutent pendant une longue période, même si les ressources informatiques utilisées sont négligeables. Une autre option est de soumettre le processus Nextflow principal en tant que tache sur le cluster.

!!! remarque

    Cela nécessite que la configuration de votre cluster permette de lancer des tâches à partir des nœuds de travail, car Nextflow soumettra de nouvelles tâches et les gérera à partir d'ici.

Par exemple, si votre cluster utilise Slurm comme planificateur de tâches, vous pouvez créer un fichier similaire à celui ci-dessous :

```bash linenums="1" title="launch_nf.sh"
#!/bin/bash
#SBATCH --partition WORK
#SBATCH --mem 5G
#SBATCH -c 1
#SBATCH -t 12:00:00

WORKFLOW=$1
CONFIG=$2

# Utiliser un environnement conda où vous avez installé Nextflow
# (peut ne pas être nécessaire si vous l'avez installé d'une autre manière)
conda activate nextflow

nextflow -C ${CONFIG} run ${WORKFLOW}
```

Puis soumettez-le avec :

```bash linenums="1"
sbatch launch_nf.sh /home/my_user/path/my_workflow.nf /home/my_user/path/my_config_file.conf
```

Vous trouverez plus de détails sur l'exemple ci-dessus [ici](https://lescailab.unipv.it/guides/eos_guide/use_nextflow.html#large-testing-or-production).
Vous trouverez d'autres conseils pour l'exécution de Nextflow sur HPC dans les articles de blog suivants :

-   [5 astuces Nextflow pour les utilisateurs HPC](https://www.nextflow.io/blog/2021/5_tips_for_hpc_users.html)
-   [Cinq astuces supplémentaires pour les utilisateurs de Nextflow sur le HPC](https://www.nextflow.io/blog/2021/5-more-tips-for-nextflow-user-on-hpc.html)

### Configurer le processus par nom

Dans les applications réelles, des tâches différentes nécessitent des ressources informatiques différentes. Il est possible de définir les ressources pour une tâche spécifique en utilisant la commande `withName:` suivie du nom du processus :

```groovy linenums="1"
process {
    executor = 'slurm'
    queue = 'short'
    memory = '10 GB'
    time = '30 min'
    cpus = 4

    withName: FOO {
        cpus = 2
        memory = '20 GB'
        queue = 'short'
    }

    withName: BAR {
        cpus = 4
        memory = '32 GB'
        queue = 'long'
    }
}
```

!!! exercice

    Exécuter le script RNA-Seq (`script7.nf`) de tout à l'heure, mais spécifier que le processus `QUANTIFICATION` nécessite 2 CPUs et 5 GB de mémoire, dans le fichier `nextflow.config`.

    ??? solution

        ```groovy
        process {
            withName: QUANTIFICATION {
                cpus = 2
                memory = '5 GB'
            }
        }
        ```

### Configurer le processus par étiquettes

Lorsqu'une application de workflow est composée de nombreux processus, il peut être difficile de dresser la liste de tous les noms de processus et de choisir des ressources pour chacun d'entre eux dans le fichier de configuration.

Une meilleure stratégie consiste à annoter les processus avec une directive [label](https://www.nextflow.io/docs/latest/process.html#label). Spécifiez ensuite les ressources dans le fichier de configuration utilisé pour tous les processus ayant le même label.

Le script du workflow :

```groovy linenums="1"
process TASK1 {
    label 'long'

    script:
    """
    first_command --here
    """
}

process TASK2 {
    label 'short'

    script:
    """
    second_command --here
    """
}
```

Le fichier de configuration :

```groovy linenums="1"
process {
    executor = 'slurm'

    withLabel: 'short' {
        cpus = 4
        memory = '20 GB'
        queue = 'alpha'
    }

    withLabel: 'long' {
        cpus = 8
        memory = '32 GB'
        queue = 'omega'
    }
}
```

### Configurer plusieurs containers

Les containers peuvent être définis pour chaque processus de votre flux de travail. Vous pouvez définir leurs conteneurs dans un fichier de configuration, comme indiqué ci-dessous :

```groovy linenums="1"
process {
    withName: FOO {
        container = 'some/image:x'
    }
    withName: BAR {
        container = 'other/image:y'
    }
}

docker.enabled = true
```

!!! Astuce

    Dois-je utiliser un seul container _fat_ ou plusieurs containers _slim_ ? Les deux approches ont des avantages et des inconvénients. Un container unique est plus simple à construire et à maintenir, mais lorsque vous utilisez de nombreux outils, l'image peut devenir très volumineuse et les outils peuvent créer des conflits entre eux. L'utilisation d'un container pour chaque processus peut donner lieu à de nombreuses images différentes à construire et à maintenir, en particulier lorsque les processus de votre workflow utilisent des outils différents pour chaque tâche.

Pour en savoir plus sur les sélecteurs de processus de configuration, consultez [ce lien](https://www.nextflow.io/docs/latest/config.html#process-selectors).

## Configuration des profils

Les fichiers de configuration peuvent contenir la définition d'un ou plusieurs _profils_. Un profil est un ensemble d'attributs de configuration qui peuvent être activés/choisis lors du lancement de l'exécution d'un workflow en utilisant l'option de ligne de commande `-profile`.

Les profils de configuration sont définis en utilisant la portée spéciale `profiles` qui regroupe les attributs appartenant au même profil en utilisant un préfixe commun. Par exemple :

```groovy linenums="1"
profiles {
    standard {
        params.genome = '/local/path/ref.fasta'
        process.executor = 'local'
    }

    cluster {
        params.genome = '/data/stared/ref.fasta'
        process.executor = 'sge'
        process.queue = 'long'
        process.memory = '10 GB'
        process.conda = '/some/path/env.yml'
    }

    cloud {
        params.genome = '/data/stared/ref.fasta'
        process.executor = 'awsbatch'
        process.container = 'cbcrg/imagex'
        docker.enabled = true
    }

}
```

Cette configuration définit trois profils différents : `standard`, `cluster` et `cloud` qui définissent différentes stratégies de configuration de processus en fonction de la plateforme d'exécution cible. Par convention, le profil `standard` est implicitement utilisé lorsqu'aucun autre profil n'est spécifié par l'utilisateur.

Pour activer un profil spécifique, utilisez l'option `-profile` suivie du nom du profil :

```bash
nextflow run <your script> -profile cluster
```

!!! astuce

    Il est possible de spécifier deux profils de configuration ou plus en séparant les noms des profils par une virgule :

    ```bash
    nextflow run <your script> -profile standard,cloud
    ```

## Déploiement dans le cloud

[AWS Batch](https://aws.amazon.com/batch/) est un service informatique géré qui permet l'exécution de charges de travail containérisées dans l'infrastructure cloud d'Amazon.

Nextflow fournit un support intégré pour AWS Batch qui permet le déploiement transparent d'un workflow Nextflow dans le cloud, en déchargeant les exécutions de processus en tant que tâches Batch.

Une fois que l'environnement Batch est configuré, spécifiez les types d'instances à utiliser et le nombre maximum de CPU à allouer, vous devez créer un fichier de configuration Nextflow comme celui présenté ci-dessous :

!!! info ""

    Cliquez sur les icônes :material-plus-circle : dans le code pour obtenir des explications.

```groovy linenums="1"
process.executor = 'awsbatch' // (1)!
process.queue = 'nextflow-ci' // (2)!
process.container = 'nextflow/rnaseq-nf:latest' // (3)!
workDir = 's3://nextflow-ci/work/' // (4)!
aws.region = 'eu-west-1' // (5)!
aws.batch.cliPath = '/home/ec2-user/miniconda/bin/aws' // (6)!
```

1. Définir AWS Batch comme l'exécuteur pour exécuter les processus dans le workflow
2. Le nom de la file d'attente informatique définie dans l'environnement Batch
3. L'image du container Docker à utiliser pour exécuter chaque tâche
4. Le répertoire de travail du workflow doit être un bucket AWS S3.
5. La région AWS à utiliser
6. Chemin d'accès à l'outil AWS cli nécessaire pour télécharger des fichiers vers/depuis le container.

!!! astuce

    La meilleure pratique consiste à conserver ce paramètre en tant que profil distinct dans le fichier de configuration de votre flux de travail. Cela permet de l'exécuter à l'aide d'une simple commande.

    ```bash
    nextflow run script7.nf -profile amazon
    ```

Les détails complets sur le déploiement par lots d'AWS sont disponibles sur [ce lien](https://www.nextflow.io/docs/latest/aws.html#aws-batch).

## Montages des volumes

Les volumes Elastic Block Storage (EBS) (ou tout autre type de stockage pris en charge) peuvent être montés dans le Container de tâches à l'aide de l'extrait de configuration suivant :

```groovy
aws {
    batch {
        volumes = '/some/path'
    }
}
```

Plusieurs volumes peuvent être spécifiés en utilisant des chemins d'accès séparés par des virgules. La syntaxe habituelle de montage de volume de Docker peut être utilisée pour définir des volumes complexes pour lesquels le chemin du conteneur est différent du chemin de l'hôte ou pour spécifier une option de lecture seule :

```groovy
aws {
    region = 'eu-west-1'
    batch {
        volumes = ['/tmp', '/host/path:/mnt/path:ro']
    }
}
```

!!! astuce

    Il s'agit d'une configuration globale qui doit être spécifiée dans un fichier de configuration Nextflow et qui sera appliquée à **toutes** les exécutions de processus.

!!! avertissement

    Nextflow s'attend à ce que les chemins d'accès soient disponibles. Il ne gère pas la mise à disposition de volumes EBS ou d'un autre type de stockage.

## Définition des tâches personnalisées

Nextflow crée automatiquement les Batch [definitions de taches](https://docs.aws.amazon.com/batch/latest/userguide/job_definitions.html) nécessaires à l'exécution de vos processus de workflow. Il n'est donc pas nécessaire de les définir avant d'exécuter votre workflow.

Cependant, vous pouvez toujours avoir besoin de spécifier une définition de travail personnalisée pour permettre un contrôle fin des paramètres de configuration d'un travail spécifique (par exemple, pour définir des chemins de montage personnalisés ou d'autres paramètres spéciaux d'un batch de taches).

Pour utiliser votre propre définition de travail dans un workflow Nextflow, utilisez-la à la place du nom de l'image du conteneur, en la préfixant avec la chaîne `job-definition://`. Par exemple :

```groovy
process {
    container = 'job-definition://your-job-definition-name'
}
```

## Image personnalisée

Comme Nextflow exige que l'outil AWS CLI soit accessible dans l'environnement informatique, une solution courante consiste à créer une Amazon Machine Image (AMI) personnalisée et à l'installer de manière autonome (par exemple à l'aide du gestionnaire de paquets Conda).

!!! avertissement

    Lorsque vous créez votre AMI personnalisée pour AWS Batch, assurez-vous d'utiliser l'AMI Amazon ECS-Optimized Amazon Linux comme image de base.

L'extrait suivant montre comment installer AWS CLI avec Miniconda :

```bash linenums="1"
sudo yum install -y bzip2 wget
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -f -p $HOME/miniconda
$HOME/miniconda/bin/conda install -c conda-forge -y awscli
rm Miniconda3-latest-Linux-x86_64.sh
```

!!! remarque

    L'outil `aws` sera placé dans un répertoire nommé `bin` dans le dossier d'installation principal. Les outils ne fonctionneront pas correctement si vous modifiez la structure de ce répertoire après l'installation.

Enfin, spécifiez le chemin complet `aws` dans le fichier de configuration de Nextflow comme indiqué ci-dessous :

```groovy
aws.batch.cliPath = '/home/ec2-user/miniconda/bin/aws'
```

## Lancer le modèle

Une autre approche consiste à créer une AMI personnalisée à l'aide d'un [modèle de lancement](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html) qui installe l'outil AWS CLI lors du démarrage de l'instance via des données utilisateur personnalisées.

Dans le tableau de bord EC2, créez un modèle de lancement en spécifiant le champ de données de l'utilisateur :

```bash linenums="1"
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

##!/bin/sh
### install required deps
set -x
export PATH=/usr/local/bin:$PATH
yum install -y jq python27-pip sed wget bzip2
pip install -U boto3

### install awscli
USER=/home/ec2-user
wget -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -f -p $USER/miniconda
$USER/miniconda/bin/conda install -c conda-forge -y awscli
rm Miniconda3-latest-Linux-x86_64.sh
chown -R ec2-user:ec2-user $USER/miniconda

--//--
```

Créez ensuite un nouvel environnement informatique dans le tableau de bord Batch et indiquez le modèle de lancement nouvellement créé dans le champ correspondant.

## Déploiements hybrides

Nextflow permet l'utilisation de plusieurs exécuteurs dans la même application de workflow. Cette fonctionnalité permet de déployer des charges de travail hybrides dans lesquelles certains travaux sont exécutés sur l'ordinateur local ou le cluster de calcul local, et d'autres travaux sont déchargés sur le service AWS Batch.

Pour activer cette fonctionnalité, utilisez un ou plusieurs [selecteur de processes](https://www.nextflow.io/docs/latest/config.html#config-process-selectors) dans votre fichier de configuration Nextflow.

Par exemple, appliquez la [configuration AWS Batch](https://www.nextflow.io/docs/latest/aws.html#configuration) uniquement à un sous-ensemble de processus dans votre flux de travail. Vous pouvez essayer ce qui suit :

```groovy linenums="1"
process {
    executor = 'slurm' // (1)!
    queue = 'short' // (2)!

    withLabel: bigTask {  // (3)!
        executor = 'awsbatch' // (4)!
        queue = 'my-batch-queue' // (5)!
        container = 'my/image:tag' // (6)!
    }
}

aws {
    region = 'eu-west-1' // (7)!
}
```

1. Définir `slurm` comme exécuteur par défaut
2. Définir la file d'attente pour le cluster SLURM
3. Mise en place de processus avec l'étiquette `bigTask`
4. Définir `awsbatch` comme l'exécuteur pour le(s) processus avec le label `bigTask`.
5. Définir la file d'attente pour le(s) processus avec le label `bigTask`.
6. Définir l'image du container à déployer pour le(s) processus avec le label `bigTask`.
7. Définir la région pour l'exécution par batch
