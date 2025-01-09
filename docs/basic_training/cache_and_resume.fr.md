---
titre: Cache et reprise
description: Atelier de formation de base Nextflow
---

# Cache d'exécution et reprise

Le mécanisme de mise en cache de Nextflow fonctionne en attribuant un identifiant unique à chaque tâche qui est utilisé pour créer un répertoire d'exécution distinct où les tâches sont exécutées et les résultats stockés.

L'identifiant unique de la tâche est généré sous la forme d'une valeur de hachage de 128 bits composée des valeurs d'entrée de la tâche, des fichiers et de la chaîne de commande.

Le workflow du répertoire work est organisé comme indiqué ci-dessous :

```txt
work/
├── 12
│   └── 1adacb582d2198cd32db0e6f808bce
│       ├── genome.fa -> /data/../genome.fa
│       └── index
│           ├── hash.bin
│           ├── header.json
│           ├── indexing.log
│           ├── quasi_index.log
│           ├── refInfo.json
│           ├── rsd.bin
│           ├── sa.bin
│           ├── txpInfo.bin
│           └── versionInfo.json
├── 19
│   └── 663679d1d87bfeafacf30c1deaf81b
│       ├── ggal_gut
│       │   ├── aux_info
│       │   │   ├── ambig_info.tsv
│       │   │   ├── expected_bias.gz
│       │   │   ├── fld.gz
│       │   │   ├── meta_info.json
│       │   │   ├── observed_bias.gz
│       │   │   └── observed_bias_3p.gz
│       │   ├── cmd_info.json
│       │   ├── libParams
│       │   │   └── flenDist.txt
│       │   ├── lib_format_counts.json
│       │   ├── logs
│       │   │   └── salmon_quant.log
│       │   └── quant.sf
│       ├── ggal_gut_1.fq -> /data/../ggal_gut_1.fq
│       ├── ggal_gut_2.fq -> /data/../ggal_gut_2.fq
│       └── index -> /data/../asciidocs/day2/work/12/1adacb582d2198cd32db0e6f808bce/index
```

!!! info

    Vous pouvez créer ces plots en utilisant la fonction `tree` si vous l'avez installée. Sur les systèmes d'exploitation basés sur Debian, il suffit de `sudo apt install -y tree` ou, pour macOS, d'utiliser Homebrew : `brew install tree`

## Comment fonctionne la reprise

L'option de ligne de commande `-resume` permet de poursuivre l'exécution d'un workflow à partir de la dernière étape qui s'est achevée avec succès :

```bash
nextflow run <script> -resume
```

En pratique, le workflow est exécuté depuis le début. Cependant, avant de lancer l'exécution d'un processus, Nextflow utilise l'identifiant unique de la tâche pour vérifier si le répertoire work existe déjà et s'il contient un état de sortie de commande valide avec les fichiers de sortie attendus.

Si cette condition est remplie, l'exécution de la tâche est sautée et les résultats calculés précédemment sont utilisés comme résultats du processus.

La première tâche pour laquelle une nouvelle sortie est calculée invalide toutes les exécutions en aval dans le DAG restant.

## repertoire Work

Les répertoires de travail des tâches sont créés par défaut dans le dossier `work` du chemin de lancement. Ce dossier est censé être une zone de stockage **scratch** qui peut être nettoyée une fois le calcul terminé.

!!! note

    Les résultats finaux du workflow sont censés être stockés dans un emplacement différent spécifié à l'aide d'une ou plusieurs directives [publishDir](https://www.nextflow.io/docs/latest/process.html#publishdir).

!!! warning

    Veillez à supprimer votre répertoire work de temps en temps, sinon votre machine/environnement risque d'être rempli de fichiers inutilisés.

Un emplacement différent pour le répertoire d'exécution work peut être spécifié en utilisant l'option de ligne de commande `-w`. Par exemple :

```bash
nextflow run <script> -w /some/scratch/dir
```

!!! warning

    Si vous supprimez ou déplacez le workflow du répertoire work, cela empêchera l'utilisation de la fonction de resume lors des exécutions suivantes.

Le code de hachage des fichiers d'entrée est calculé en utilisant :

-   le chemin d'accès complet au fichier
-   la taille du fichier
-   l'horodatage de la dernière modification

Par conséquent, le simple fait de ** toucher** un fichier invalidera l'exécution de la tâche correspondante.

## Comment organiser des expériences _in-silico_ ?

Il est conseillé d'organiser chaque **expérience** dans son propre dossier. Les principaux paramètres d'entrée de l'expérience doivent être spécifiés en utilisant un fichier de configuration Nextflow. Cela facilite le suivi et la réplication d'une expérience dans le temps.

!!! note

    Dans la même expérience, le même flux de travail peut être exécuté plusieurs fois, cependant, le lancement simultané de deux (ou plus) instances Nextflow dans le même répertoire doit être évité.

La commande `nextflow log` liste les exécutions effectuées dans le dossier courant :

```console
$ nextflow log

TIMESTAMP            DURATION  RUN NAME          STATUS  REVISION ID  SESSION ID                            COMMAND
2019-05-06 12:07:32  1.2s      focused_carson    ERR     a9012339ce   7363b3f0-09ac-495b-a947-28cf430d0b85  nextflow run hello
2019-05-06 12:08:33  21.1s     mighty_boyd       OK      a9012339ce   7363b3f0-09ac-495b-a947-28cf430d0b85  nextflow run rnaseq-nf -with-docker
2019-05-06 12:31:15  1.2s      insane_celsius    ERR     b9aefc67b4   4dc656d2-c410-44c8-bc32-7dd0ea87bebf  nextflow run rnaseq-nf
2019-05-06 12:31:24  17s       stupefied_euclid  OK      b9aefc67b4   4dc656d2-c410-44c8-bc32-7dd0ea87bebf  nextflow run rnaseq-nf -resume -with-docker
```

Vous pouvez utiliser l'**identifiant de session** ou le **nom d'exécution** pour récupérer une exécution spécifique. Par exemple:

```bash
nextflow run rnaseq-nf -resume mighty_boyd
```

## Provenance de l'exécution

La commande `log`, lorsqu'elle est fournie avec un **nom d'exécution** ou un **identifiant de session**, peut renvoyer de nombreuses informations utiles sur l'exécution d'un workflow qui peuvent être utilisées pour créer un rapport de provenance.

Par défaut, il énumère les répertoires de travail utilisés pour calculer chaque tâche. Par exemple :

```console
$ nextflow log tiny_fermat

/data/.../work/7b/3753ff13b1fa5348d2d9b6f512153a
/data/.../work/c1/56a36d8f498c99ac6cba31e85b3e0c
/data/.../work/f7/659c65ef60582d9713252bcfbcc310
/data/.../work/82/ba67e3175bd9e6479d4310e5a92f99
/data/.../work/e5/2816b9d4e7b402bfdd6597c2c2403d
/data/.../work/3b/3485d00b0115f89e4c202eacf82eba
```

L'option `-f` (fields) peut être utilisée pour spécifier quelles métadonnées doivent être imprimées par la commande `log`. Par exemple :

```console
$ nextflow log tiny_fermat -f 'process,exit,hash,duration'

index    0   7b/3753ff  2.0s
fastqc   0   c1/56a36d  9.3s
fastqc   0   f7/659c65  9.1s
quant    0   82/ba67e3  2.7s
quant    0   e5/2816b9  3.2s
multiqc  0   3b/3485d0  6.3s
```

La liste complète des domaines disponibles peut être consultée à l'aide de la commande :

```bash
nextflow log -l
```

L'option `-F` permet de spécifier des critères de filtrage pour n'imprimer qu'un sous-ensemble de tâches. Par exemple :

```console
$ nextflow log tiny_fermat -F 'process =~ /fastqc/'

/data/.../work/c1/56a36d8f498c99ac6cba31e85b3e0c
/data/.../work/f7/659c65ef60582d9713252bcfbcc310
```

Cela peut être utile pour localiser les répertoires de travail d'une tâche spécifique.

Enfin, l'option `-t` permet de créer un rapport de provenance personnalisé de base, en affichant un fichier modèle dans le format de votre choix. Par exemple:

```html
<div>
    <h2>${name}</h2>
    <div>
        Script:
        <pre>${script}</pre>
    </div>

    <ul>
        <li>Exit: ${exit}</li>
        <li>Status: ${status}</li>
        <li>Work dir: ${workdir}</li>
        <li>Container: ${container}</li>
    </ul>
</div>
```

!!! exercise

    Sauvegardez l'extrait ci-dessus dans un fichier nommé `template.html`. Lancez ensuite cette commande (en utilisant l'identifiant correct pour votre exécution, par exemple `tiny_fermat`) :

    ```bash
    nextflow log tiny_fermat -t template.html > prov.html
    ```

    Enfin, ouvrez le fichier `prov.html` avec un navigateur.

## Dépanner la reprise

La possibilité de reprendre les workflows est une fonctionnalité clé de Nextflow, mais elle ne fonctionne pas toujours comme vous l'attendez. Dans cette section, nous allons passer en revue quelques raisons courantes pour lesquelles Nextflow peut ignorer vos résultats mis en cache.

!!! tip

    Pour en savoir plus sur le mécanisme de reprise et sur la manière de résoudre les problèmes, veuillez consulter les trois articles de blog suivants :

     1. [Démystifier la reprise de  Nextflow](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html)
     2. [Depanner la reprise Nextflow resume](https://www.nextflow.io/blog/2019/troubleshooting-nextflow-resume.html)
     3. [Analyse du comportement des pipelines en matière de mise en cache](https://nextflow.io/blog/2022/caching-behavior-analysis.html)

#### Fichier d'entrée modifié

Assurez-vous qu'il n'y a pas de changement dans le(s) fichier(s) d'entrée. N'oubliez pas que le hachage unique de la tâche est calculé en tenant compte du chemin complet du fichier, de l'horodatage de la dernière modification et de la taille du fichier. Si l'une de ces informations a changé, le workflow sera réexécuté même si le contenu d'entrée est identique.

#### Un processus modifie une entrée

Un processus ne doit jamais modifier les fichiers d'entrée, sinon le `resume` pour les exécutions futures sera invalidé pour la même raison que celle expliquée dans le point précédent.

#### Attributs de fichiers incohérents

Certains systèmes de fichiers partagés, tels que [NFS](https://en.wikipedia.org/wiki/Network_File_System), peuvent signaler un horodatage incohérent (c'est-à-dire un horodatage différent pour le même fichier) même s'il n'a pas été modifié. Pour éviter ce problème, utilisez la [stratégie de cache indulgente](https://www.nextflow.io/docs/latest/process.html#cache).

#### Condition de course dans une variable globale

Nextflow est conçu pour simplifier la programmation parallèle sans se préoccuper des conditions de course et de l'accès aux ressources partagées. L'un des rares cas où une condition de course peut survenir est l'utilisation d'une variable globale avec deux (ou plus) opérateurs.
Par exemple:

```groovy linenums="1"
Channel
    .of(1, 2, 3)
    .map { it -> X = it; X += 2 }
    .view { "ch1 = $it" }

Channel
    .of(1, 2, 3)
    .map { it -> X = it; X *= 2 }
    .view { "ch2 = $it" }
```

Le problème dans cet extrait est que la variable `X` dans la définition de la fermeture est définie dans la portée globale. Par conséquent, puisque les opérateurs sont exécutés en parallèle, la valeur `X` peut être écrasée par l'autre invocation de `map`.

L'implémentation correcte nécessite l'utilisation du mot-clé `def` pour déclarer la variable **locale**.

```groovy linenums="1"
Channel
    .of(1, 2, 3)
    .map { it -> def X = it; X += 2 }
    .println { "ch1 = $it" }

Channel
    .of(1, 2, 3)
    .map { it -> def X = it; X *= 2 }
    .println { "ch2 = $it" }
```

#### Canaux d'entrée non déterministes

Si l'ordre des canaux de flux de données est garanti - les données sont lues dans l'ordre dans lequel elles sont écrites dans le canal - il faut savoir qu'il n'y a aucune garantie que les éléments conservent leur ordre dans le canal de _sortie_ du processus. En effet, un processus peut engendrer plusieurs tâches, qui peuvent s'exécuter en parallèle. Par exemple, l'opération sur le deuxième élément peut se terminer plus tôt que l'opération sur le premier élément, ce qui modifie l'ordre du canal de sortie.

En pratique, considérons l'extrait suivant :

```groovy linenums="1"
process FOO {
    input:
    val x

    output:
    tuple val(task.index), val(x)

    script:
    """
    sleep \$((RANDOM % 3))
    """
}

workflow {
    channel.of('A', 'B', 'C', 'D') | FOO | view
}
```

Tout comme nous l'avons vu au début de ce tutoriel avec HELLO WORLD ou WORLD HELLO, la sortie de l'extrait ci-dessus peut être :

```console
[3, C]
[4, D]
[2, B]
[1, A]
```

... et cet ordre sera probablement différent à chaque fois que le flux de travail sera exécuté.

Imaginons maintenant que nous ayons deux processus de ce type, dont les canaux de sortie servent de canaux d'entrée à un troisième processus. Les deux canaux seront indépendamment aléatoires, de sorte que le troisième processus ne doit pas s'attendre à ce qu'ils conservent une séquence appariée. S'il suppose que le premier élément du canal de sortie du premier processus est lié au premier élément du canal de sortie du deuxième processus, il y aura inadéquation.

Une solution courante consiste à utiliser ce que l'on appelle communément une _meta map_. Un objet groovy contenant des informations sur les échantillons est transmis avec les résultats du fichier dans un canal de sortie sous la forme d'un tuple. Cet objet peut ensuite être utilisé pour associer des échantillons provenant de canaux distincts en vue d'une utilisation en aval. Par exemple, au lieu de mettre juste `/some/path/myoutput.bam` dans un canal, vous pouvez utiliser `['SRR123', '/some/path/myoutput.bam']` pour vous assurer que les processus ne sont pas en conflit. Regardez l'exemple ci-dessous :

```groovy linenums="1"
// For example purposes only.
// These would normally be outputs from upstream processes.
Channel
    .of(
        [[id: 'sample_1'], '/path/to/sample_1.bam'],
        [[id: 'sample_2'], '/path/to/sample_2.bam']
    )
    .set { bam }

// NB: sample_2 is now the first element, instead of sample_1
Channel
    .of(
        [[id: 'sample_2'], '/path/to/sample_2.bai'],
        [[id: 'sample_1'], '/path/to/sample_1.bai']
    )
    .set { bai }

// Instead of feeding the downstream process with these two channels separately, we can
// join them and provide a single channel where the sample meta map is implicitly matched:
bam
    .join(bai)
    | PROCESS_C
```

Si les méta-cartes ne sont pas possibles, une alternative est d'utiliser la directive de processus [`fair`](https://nextflow.io/docs/edge/process.html#fair). Lorsque cette directive est spécifiée, Nextflow garantira que l'ordre des sorties correspondra à l'ordre des entrées. Il est important de mentionner que l'ordre dans lequel les tâches seront terminées ne suivra pas nécessairement l'ordre dans le canal d'entrée, mais Nextflow garantit qu'à la fin de celui-ci, le canal de sortie contiendra les éléments dans l'ordre respectif.

!!! warning

     En fonction de votre situation, l'utilisation de la directive `fair` peut entraîner une diminution des performances.
