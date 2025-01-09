---
description: Atelier de formation de base sur Nextflow
---

# Workflow simple de RNA-Seq

Pour démontrer un scénario biomédical réel, nous mettrons en œuvre une preuve de concept de flux de travail RNA-Seq qui :

1. Indexer un fichier de transcriptome
2. Effectuer des contrôles de qualité
3. Effectuer la quantification
4. Créer un rapport MultiQC

Pour ce faire, nous utiliserons une série de sept scripts, chacun d'entre eux s'appuyant sur le précédent pour créer un flux de travail complet. Vous pouvez les trouver dans le dossier du didacticiel (`script1.nf` - `script7.nf`). Ces scripts utiliseront des outils tiers connus des bioinformaticiens mais qui peuvent être nouveaux pour vous, nous les présenterons donc brièvement ci-dessous.

1. [Salmon](https://combine-lab.github.io/salmon/) est un outil permettant de quantifier les molécules connues sous le nom de transcrits à l'aide d'un type de données appelé données RNA-seq.
2. [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) est un outil permettant d'effectuer un contrôle de la qualité des données de séquences à haut débit. Vous pouvez le considérer comme un moyen d'évaluer la qualité de vos données.
3. [MultiQC](https://multiqc.info) recherche les journaux d'analyse dans un répertoire donné et compile un rapport HTML. Il s'agit d'un outil d'usage général, parfait pour résumer les résultats de nombreux outils bioinformatiques.

Même si ces outils ne sont pas ceux que vous utiliserez dans votre pipeline, ils peuvent être remplacés par n'importe quel outil courant de votre secteur. C'est ca la puissance de Nextflow !

## Définir les paramètres du workflow

Les paramètres sont des entrées et des options qui peuvent être modifiées lors de l'exécution du flux de travail.

Le script `script1.nf` définit les paramètres d'entrée du workflow.

```groovy
params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.multiqc = "$projectDir/multiqc"

println "reads: $params.reads"
```

Exécutez-le en utilisant la commande suivante :

```bash
nextflow run script1.nf
```

Essayez de spécifier un paramètre d'entrée différent dans votre commande d'exécution, par exemple :

```bash
nextflow run script1.nf --reads '/workspace/gitpod/nf-training/data/ggal/lung_{1,2}.fq'
```

### :material-progress-question: Exercices

!!! exercise

    Modifiez le fichier `script1.nf` en ajoutant un quatrième paramètre nommé `outdir` et définissez-le comme chemin par défaut qui sera utilisé comme répertoire de sortie du workflow.

    ??? Solution

        ```groovy
        params.reads = "$projectDir/data/ggal/gut_{1,2}.fq"
        params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
        params.multiqc = "$projectDir/multiqc"
        params.outdir = "results"
        ```

!!! exercise

    Modifier `script1.nf` pour imprimer tous les paramètres du workflow en utilisant une seule commande `log.info` sous la forme d'une [chaîne multiligne](https://www.nextflow.io/docs/latest/script.html#multi-line-strings).

    !!! tip ""

        :material-lightbulb: regarde l'example [ici](https://github.com/nextflow-io/rnaseq-nf/blob/3b5b49f/main.nf#L41-L48).


    ??? Solution

        Ajoutez ce qui suit à votre fichier script:

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

### :material-check-all: Résumé

Au cours de cette étape, vous avez appris:

1. Comment définir les paramètres dans votre script de workflow
2. Comment passer des paramètres en utilisant la ligne de commande
3. L'utilisation des variables `$var` et `${var}`.
4. Comment utiliser des chaînes de caractères multilignes
5. Comment utiliser `log.info` pour imprimer des informations et les sauvegarder dans le fichier d'exécution du journal.

## Créer un fichier d'index du transcriptome

Nextflow permet l'exécution de n'importe quelle commande ou script en utilisant une définition `processus`.

Un "processus" est défini par trois déclarations principales : le processus [`input`](https://www.nextflow.io/docs/latest/process.html#inputs), [`output`](https://www.nextflow.io/docs/latest/process.html#outputs) et la commande [`script`](https://www.nextflow.io/docs/latest/process.html#script).

Pour ajouter une étape de traitement `INDEX` du transcriptome, essayez d'ajouter les blocs de code suivants à votre `script1.nf`. Alternativement, ces blocs de code ont déjà été ajoutés à `script2.nf`.

```groovy
/*
 * définir le processus INDEX qui crée un index binaire
 * compte tenu du fichier de transcriptome
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

En outre, ajoutez un champ d'application de workflow contenant une définition de canal d'entrée et le processus d'indexation :

```groovy
workflow {
    index_ch = INDEX(params.transcriptome_file)
}
```

Ici, le paramètre `params.transcriptome_file` est utilisé comme entrée pour le processus `INDEX`. Le processus `INDEX` (utilisant l'outil `salmon`) crée `salmon_index`, un transcriptome indexé qui est transmis en sortie au canal `index_ch`.

!!! info

    La déclaration `input` définit une variable de chemin `transcriptome` qui est utilisée dans le `script` comme référence (en utilisant le symbole du dollar) dans la ligne de commande Salmon.

!!! warning

    Les besoins en ressources tels que les CPUs et les limites de mémoire peuvent changer avec les différentes exécutions de workflow et les plateformes. Nextflow peut utiliser `$task.cpus` comme variable pour le nombre de CPU. Voir [process directives documentation](https://www.nextflow.io/docs/latest/process.html#directives) pour plus de détails.

Exécutez-le en utilisant la commande :

```bash
nextflow run script2.nf
```

L'exécution échouera car `salmon` n'est pas installé dans votre environnement.

Ajoutez l'option de ligne de commande `-with-docker` pour lancer l'exécution à travers un conteneur Docker, comme indiqué ci-dessous :

```bash
nextflow run script2.nf -with-docker
```

Cette fois l'exécution fonctionnera car elle utilise le conteneur Docker `nextflow/rnaseq-nf` qui est défini dans le fichier `nextflow.config` dans votre répertoire courant. Si vous exécutez ce script localement, vous devrez télécharger Docker sur votre machine, vous connecter et activer Docker, et autoriser le script à télécharger le conteneur contenant les scripts d'exécution. Vous pouvez en savoir plus sur Docker [ici](https://www.nextflow.io/docs/latest/docker.html).

Pour éviter d'ajouter `-with-docker` à chaque fois que vous exécutez le script, ajoutez la ligne suivante au fichier `nextflow.config` :

```groovy
docker.enabled = true
```

### :material-progress-question: Exercices

!!! exercise

    Activez l'exécution Docker par défaut en ajoutant le paramètre ci-dessus dans le fichier `nextflow.config`.

!!! exercise

    Imprimer la sortie du canal `index_ch` en utilisant l'opérateur [view](https://www.nextflow.io/docs/latest/operator.html#view).

    ??? Solution

        Ajoutez ce qui suit à la fin de votre bloc de workflow dans votre fichier script

        ```groovy
        index_ch.view()
        ```

!!! exercise

    Si vous disposez de plus d'unités centrales, essayez de modifier votre script pour demander plus de ressources pour ce processus. Par exemple, voir la [directive docs](https://www.nextflow.io/docs/latest/process.html#cpus). `$task.cpus` est déjà spécifié dans ce script, donc définir le nombre de CPUs comme une directive indiquera à Nextflow comment exécuter ce processus, en termes de nombre de CPUs.

    ??? Solution

        Ajouter `cpus 2` au début du processus d'indexation :

        ```groovy
        process INDEX {
            cpus 2

            input:
            ...
        ```

        Vérifiez ensuite qu'il a fonctionné en regardant le script exécuté dans le répertoire work. Cherchez l'hexadécimal (par exemple `work/7f/f285b80022d9f61e82cd7f90436aa4/`), puis `cat` le fichier `.command.sh`.

!!! exercise "Exercice Bonus"

    Utilisez la commande `tree work` pour voir comment Nextflow organise le répertoire work du processus. Vérifiez [ici](https://www.tecmint.com/linux-tree-command-examples/) si vous avez besoin de télécharger `tree`.

    ??? Solution

        Il devrait ressembler à ceci :

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

### :material-check-all: Résumé

Dans cette étape, vous avez appris

1. Comment définir un processus exécutant une commande personnalisée
2. Comment déclarer les entrées d'un processus
3. Comment déclarer les sorties d'un processus
4. Comment imprimer le contenu d'un canal
5. Comment accéder au nombre de CPU disponibles

## Collecter les fichiers lus par paires

Cette étape montre comment faire correspondre les fichiers **read** par paires, afin qu'ils puissent être mis en correspondance par **Salmon**.

Modifiez le script `script3.nf` en ajoutant la déclaration suivante à la dernière ligne du fichier :

```groovy
read_pairs_ch.view()
```

Sauvegardez-le et exécutez-le avec la commande suivante :

```bash
nextflow run script3.nf
```

Il s'affichera quelque chose de similaire à ceci :

```bash
[gut, [/.../data/ggal/gut_1.fq, /.../data/ggal/gut_2.fq]]
```

L'exemple ci-dessus montre comment le canal `read_pairs_ch` émet des tuples composés de deux éléments, le premier étant le préfixe de la paire lue et le second une liste représentant les fichiers actuels.

Essayez à nouveau en spécifiant différents fichiers de lecture à l'aide d'un motif global :

```bash
nextflow run script3.nf --reads 'data/ggal/*_{1,2}.fq'
```

!!! warning

    Les chemins d'accès aux fichiers qui incluent un ou plusieurs jokers, c'est-à-dire `*`, `?`, etc., DOIVENT être entourés de caractères entre guillemets simples afin d'éviter que Bash n'étende le glob.

### :material-progress-question: Exercices

!!! exercise

    Utilisez l'opérateur [set](https://www.nextflow.io/docs/latest/operator.html#set) à la place de l'affectation `=` pour définir le canal `read_pairs_ch`.

    ??? Solution

        ```groovy
        Channel
            .fromFilePairs(params.reads)
            .set { read_pairs_ch }
        ```

!!! exercise

    Utilisez l'option `checkIfExists` pour la fabrique de canaux [fromFilePairs](https://www.nextflow.io/docs/latest/channel.html#fromfilepairs) pour vérifier si le chemin spécifié contient des paires de fichiers.

    ??? Solution

        ```groovy
        Channel
            .fromFilePairs(params.reads, checkIfExists: true)
            .set { read_pairs_ch }
        ```

### :material-check-all: résumé

Au cours de cette étape, vous avez appris:

1. Comment utiliser `fromFilePairs` pour gérer les fichiers de paires de lecture
2. Comment utiliser l'option `checkIfExists` pour vérifier l'existence des fichiers d'entrée
3. Comment utiliser l'opérateur `set` pour définir une nouvelle variable de canal.

!!! info

    La déclaration d'un canal peut se situer avant le champ d'application du workflow ou à l'intérieur de celui-ci. Tant qu'elle se situe en amont du processus qui requiert le canal spécifique.

## Quantification de l'expression

Le fichier `script4.nf` ajoute un processus de `QUANTIFICATION` de l'expression des gènes et un appel à ce processus dans le champ d'application du flux de travail. La quantification nécessite les fichiers fastq du transcriptome indexé et de la paire reads de RNA-Seq.

Dans le workflow scope, notez comment le canal `index_ch` est assigné comme sortie dans le processus `INDEX`.

Ensuite, notez que le premier canal d'entrée pour le processus `QUANTIFICATION` est le `index_ch` précédemment déclaré, qui contient le `chemin` vers le `salmon_index`.

Notez également que le second canal d'entrée pour le processus de `QUANTIFICATION` est le `read_pair_ch` que nous venons de créer. C'est un `tuple` composé de deux éléments (une valeur : `sample_id` et une liste de chemins vers les lectures fastq : `reads`) afin de correspondre à la structure des éléments émis par la fabrique de canaux `fromFilePairs`.

Exécutez-la en utilisant la commande suivante :

```bash
nextflow run script4.nf -resume
```

Vous verrez l'exécution du processus `QUANTIFICATION`.

Lors de l'utilisation de l'option `-resume`, toute étape qui a déjà été traitée est sautée.

Essayez d'exécuter à nouveau le même script avec davantage de fichiers lus, comme indiqué ci-dessous :

```bash
nextflow run script4.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

Vous remarquerez que le processus `QUANTIFICATION` est exécuté plusieurs fois.

Nextflow parallélise l'exécution de votre workflow en fournissant simplement plusieurs jeux de données d'entrée à votre script.

!!! tip

    Il peut être utile d'appliquer des paramètres facultatifs à un processus spécifique à l'aide de [directives](https://www.nextflow.io/docs/latest/process.html#directives) en les spécifiant dans le corps du processus.

### :material-progress-question: Exercices

!!! exercise

    Ajout d'une directive [tag](https://www.nextflow.io/docs/latest/process.html#tag) au processus `QUANTIFICATION` pour fournir un journal d'exécution plus lisible.

    ??? Solution

        Ajoutez ce qui suit avant la déclaration d'entrée :

        ```groovy
        tag "Salmon on $sample_id"
        ```

!!! exercise

    Ajoutez une directive [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir) au processus `QUANTIFICATION` pour stocker les résultats du processus dans un répertoire de votre choix.

    ??? Solution

        Ajoutez ce qui suit avant la déclaration `input` dans le processus `QUANTIFICATION` :

        ```groovy
        publishDir params.outdir, mode: 'copy'
        ```

### :material-check-all: Résumé

Dans cette étape, vous avez appris

1. Comment connecter deux processus ensemble en utilisant les déclarations de canal
2. Comment reprendre l'exécution du script et sauter les étapes mises en cache
3. Comment utiliser la directive `tag` pour fournir une sortie d'exécution plus lisible
4. Comment utiliser la directive `publishDir` pour stocker les résultats d'un processus dans un chemin de votre choix.

## Contrôle qualité

Ensuite, nous implémentons une étape de contrôle de qualité `FASTQC` pour vos reads d'entrée (en utilisant le label `fastqc`). Les entrées sont les mêmes que les paires de reads utilisées dans l'étape `QUANTIFICATION`.

Vous pouvez l'exécuter en utilisant la commande suivante :

```bash
nextflow run script5.nf -resume
```

Nextflow DSL2 sait qu'il faut diviser les `reads_pair_ch` en deux canaux identiques car ils sont requis deux fois en tant qu'entrée pour les processus `FASTQC` et `QUANTIFICATION`.

## Rapport de MultiQC

Cette étape rassemble les résultats des processus de `QUANTIFICATION` et de `FASTQC` pour créer un rapport final à l'aide de l'outil [MultiQC](http://multiqc.info/).

Exécutez le script suivant avec la commande suivante :

```bash
nextflow run script6.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

Il crée le rapport final dans le dossier `results` du répertoire `work` actuel.

Dans ce script, notez l'utilisation des opérateurs [mix](https://www.nextflow.io/docs/latest/operator.html#mix) et [collect](https://www.nextflow.io/docs/latest/operator.html#collect) combinés ensemble pour rassembler les sorties des processus `QUANTIFICATION` et `FASTQC` en une seule entrée. Les opérateurs [Operators](https://www.nextflow.io/docs/latest/operator.html) peuvent être utilisés pour combiner et transformer les canaux.

```groovy
MULTIQC(quant_ch.mix(fastqc_ch).collect())
```

Nous voulons qu'une seule tâche de MultiQC soit exécutée pour produire un rapport. Nous utilisons donc l'opérateur de canal `mix` pour combiner les deux canaux, suivi de l'opérateur `collect`, pour retourner le contenu complet du canal en un seul élément.

### :material-check-all: Résumé

Dans cette étape, vous avez appris

1. Comment collecter plusieurs sorties vers une seule entrée avec l'opérateur `collect`.
2. Comment `mixer` deux canaux en un seul canal
3. Comment enchaîner deux ou plusieurs opérateurs ensemble

## Gérer l'événement d'achèvement

Cette étape montre comment exécuter une action lorsque le flux de travail a terminé son exécution.

Notez que les processus Nextflow définissent l'exécution de tâches **asynchrones**, c'est-à-dire qu'elles ne sont pas exécutées l'une après l'autre comme si elles étaient écrites dans le script du workflow dans un langage de programmation **impératif** commun.

Le script utilise le gestionnaire d'événement `workflow.onComplete` pour imprimer un message de confirmation lorsque le script est terminé.

Essayez de l'exécuter en utilisant la commande suivante :

```bash
nextflow run script7.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

## Notifications par e-mail

Envoyer un e-mail de notification lorsque l'exécution du flux de travail est terminée en utilisant l'option de ligne de commande `-N <adresse e-mail>`.

Note : ceci nécessite la configuration d'un serveur SMTP dans le fichier de configuration de nextflow. Vous trouverez ci-dessous un exemple de fichier `nextflow.config` montrant les paramètres à configurer :

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

Voir [mail documentation](https://www.nextflow.io/docs/latest/mail.html#mail-configuration) pour plus de détails.

## Scripts personnalisés

Les workflows du monde réel utilisent beaucoup de scripts utilisateurs personnalisés (BASH, R, Python, etc.). Nextflow vous permet d'utiliser et de gérer ces scripts de manière cohérente. Il suffit de les placer dans un répertoire nommé `bin` à la racine du projet de workflow. Ils seront automatiquement ajoutés au `PATH` d'exécution du workflow.

Par exemple, créez un fichier nommé `fastqc.sh` avec le contenu suivant :

```bash
#!/bin/bash
set -e
set -u

sample_id=${1}
reads=${2}

mkdir fastqc_${sample_id}_logs
fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
```

Sauvegardez-le, donnez-lui la permission d'exécuter et placez-le dans le répertoire `bin` comme indiqué ci-dessous :

```bash
chmod +x fastqc.sh
mkdir -p bin
mv fastqc.sh bin
```

Ensuite, ouvrez le fichier `script7.nf` et remplacez le script du processus `FASTQC` par le code suivant :

```groovy
script:
"""
fastqc.sh "$sample_id" "$reads"
"""
```

Exécutez-la comme auparavant :

```bash
nextflow run script7.nf -resume --reads 'data/ggal/*_{1,2}.fq'
```

### :material-check-all: Résumé

Dans cette étape, vous avez appris

1. Comment écrire ou utiliser des scripts personnalisés existants dans votre workflow Nextflow.
2. Comment éviter l'utilisation de chemins absolus en ayant vos scripts dans le dossier `bin/`.

## Mesures et rapports

Nextflow peut produire de multiples rapports et graphiques fournissant plusieurs mesures de temps d'exécution et des informations sur l'exécution.

Exécutez le workflow [rnaseq-nf](https://github.com/nextflow-io/rnaseq-nf) précédemment introduit comme indiqué ci-dessous :

```bash
nextflow run rnaseq-nf -with-docker -with-report -with-trace -with-timeline -with-dag dag.png
```

L'option `-with-docker` lance chaque tâche de l'exécution comme une commande d'exécution d'un conteneur Docker.

L'option `-with-report` permet la création du rapport d'exécution du workflow. Ouvrez le fichier `report.html` avec un navigateur pour voir le rapport créé avec la commande ci-dessus.

L'option `-with-trace` permet la création d'un fichier de valeurs séparées par des tabulations (TSV) contenant des informations d'exécution pour chaque tâche exécutée. Consultez le fichier `trace.txt` pour un exemple.

L'option `-with-timeline` permet la création d'un rapport sur la chronologie du flux de travail montrant comment les processus ont été exécutés au fil du temps. Cela peut être utile pour identifier les tâches qui prennent le plus de temps et les goulots d'étranglement. Voir un exemple à [ce lien](https://www.nextflow.io/docs/latest/tracing.html#timeline-report).

Enfin, l'option `-with-dag` permet le rendu de la représentation graphique acyclique directe de l'exécution du workflow. Note : Cette fonctionnalité nécessite l'installation de [Graphviz](http://www.graphviz.org/) sur votre ordinateur. Voir [ici](https://www.nextflow.io/docs/latest/tracing.html#dag-visualisation) pour plus de détails. Essayez ensuite d'exécuter :

```bash
open dag.png
```

!!! warning

    Les mesures de temps d'exécution peuvent être incomplètes pour les exécutions avec des tâches courtes, comme dans le cas de ce tutoriel.

!!! info

    Vous pouvez visualiser les fichiers HTML en cliquant avec le bouton droit de la souris sur le nom du fichier dans la barre latérale gauche et en choisissant l'option de menu **Preview**.

## Exécuter un projet à partir de GitHub

Nextflow permet l'exécution d'un projet de workflow directement à partir d'un dépositoire GitHub (ou de services similaires, par exemple BitBucket et GitLab).

Cela simplifie le partage et le déploiement de projets complexes et le suivi des modifications de manière cohérente.

Le dépositoire GitHub suivant héberge une version complète du flux de travail présenté dans ce tutoriel : <https://github.com/nextflow-io/rnaseq-nf>

Vous pouvez l'exécuter en spécifiant le nom du projet et en lançant chaque tâche de l'exécution comme une commande run d'un conteneur Docker :

```bash
nextflow run nextflow-io/rnaseq-nf -with-docker
```

Il télécharge automatiquement le conteneur et le stocke dans le dossier `$HOME/.nextflow`.

Utilisez la commande `info` pour afficher les informations sur le projet :

```bash
nextflow info nextflow-io/rnaseq-nf
```

Nextflow permet l'exécution d'une révision spécifique de votre projet en utilisant l'option de ligne de commande `-r`. Par exemple, l'option de ligne de commande `-r` permet d'exécuter une révision spécifique de votre projet :

```bash
nextflow run nextflow-io/rnaseq-nf -r v2.1 -with-docker
```

Les révisions sont définies à l'aide de tags Git ou de branches définies dans le référentiel du projet.

Les tags permettent un contrôle précis des modifications apportées à vos fichiers de projet et à vos dépendances au fil du temps.

## Plus de ressources

-   [Documentation Nextflow](http://docs.nextflow.io) - L'accueil de la documentation Nextflow.
-   [Modèles Nextflow](https://github.com/nextflow-io/patterns) - Une collection de modèles de mise en œuvre de Nextflow.
-   [CalliNGS-NF](https://github.com/CRG-CNAG/CalliNGS-NF) - Un workflow d'appel de variants mettant en œuvre les meilleures pratiques de GATK.
-   [nf-core](http://nf-co.re/) - Une collection communautaire de workflows génomiques prêts à la production.
