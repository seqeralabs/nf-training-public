---
titre: Description
du Dépannage: Traitement des erreurs et dépannage
---

# Traitement des erreurs et dépannage

## Débogage des erreurs d'exécution

Lorsqu'une exécution de processus se termine avec un statut de sortie non nul, Nextflow arrête l'exécution du workflow et signale la tâche défaillante :

!!! info ""

    Cliquez sur les icônes :material-plus-circle: dans le code pour obtenir des explications.

```bash
ERROR ~ Error executing process > 'INDEX'

Caused by: # (1)!
  Process `INDEX` terminated with an error exit status (127)

Command executed: # (2)!

  salmon index --threads 1 -t transcriptome.fa -i index

Command exit status: # (3)!
  127

Command output: # (4)!
  (empty)

Command error: # (5)!
  .command.sh: line 2: salmon: command not found

Work dir: # (6)!
  /Users/pditommaso/work/0b/b59f362980defd7376ee0a75b41f62
```

1. Une description de la cause de l'erreur
2. La commande exécutée
3. L'état de sortie de la commande
4. La sortie standard de la commande, si elle est disponible
5. L'erreur standard de la commande
6. Le répertoire de travail de la commande

Examinez attentivement toutes les données d'erreur, car elles peuvent fournir des informations précieuses pour le débogage.

Si cela ne suffit pas, `cd` dans le répertoire de travail de la tâche. Il contient tous les fichiers nécessaires pour reproduire le problème de manière isolée.

Le répertoire d'exécution de la tâche contient ces fichiers :

-   `.command.sh` : Le script de commande.
-   `.command.run` : La commande enveloppée utilisée pour exécuter la tâche.
-   `.command.out` : La sortie standard complète de la tâche.
-   `.command.err` : L'erreur standard de la tâche complète.
-   `.command.log` : La sortie de l'exécution du wrapper.
-   `.command.begin` : Fichier sentinelle créé dès que la tâche est lancée.
-   `.exitcode` : Un fichier contenant le code de sortie de la tâche.
-   Fichiers d'entrée de la tâche (liens symboliques)
-   Fichiers de sortie de la tâche

Vérifiez que le fichier `.command.sh` contient la commande attendue et que toutes les variables sont correctement résolues.

Vérifiez également l'existence des fichiers `.exitcode` et `.command.begin`, qui, s'ils sont absents, suggèrent que la tâche n'a jamais été exécutée par le sous-système (par exemple, le planificateur batch). Si le fichier `.command.begin` existe, la tâche a été lancée mais a probablement été interrompue brutalement.

Vous pouvez reproduire l'échec de l'exécution en utilisant la commande `bash .command.run` pour vérifier la cause de l'erreur.

## Ignorer les erreurs

Dans certains cas, une erreur de processus peut être attendue et ne doit pas interrompre l'exécution globale du workflow.

Pour gérer ce cas d'utilisation, définissez le processus `errorStrategy` à `ignore` :

```groovy linenums="1"
process FOO {
    errorStrategy 'ignore'

    script:
    """
    your_command --this --that
    """
}
```

Si vous souhaitez ignorer toute erreur, vous pouvez définir la même directive dans le fichier de configuration comme paramètre par défaut :

```groovy
process.errorStrategy = 'ignore'
```

## Basculement automatique en cas d'erreur

Dans de rares cas, les erreurs peuvent être causées par des conditions transitoires. Dans ce cas, une stratégie efficace consiste à réexécuter la tâche défaillante.

```groovy linenums="1"
process FOO {
    errorStrategy 'retry'

    script:
    """
    your_command --this --that
    """
}
```

En utilisant la stratégie d'erreur `retry`, la tâche est réexécutée une seconde fois si elle renvoie un statut de sortie non nul avant d'arrêter l'exécution complète du flux de travail.

La directive [maxRetries](https://www.nextflow.io/docs/latest/process.html#maxretries) peut être utilisée pour définir le nombre de tentatives de réexécution de la tâche avant de déclarer qu'elle a échoué avec une condition d'erreur.

## Réessayer avec backoff

Dans certains cas, les ressources d'exécution requises peuvent être temporairement indisponibles (par exemple, en cas de congestion du réseau). Dans ce cas, la simple réexécution de la même tâche entraînera probablement une erreur identique. Une nouvelle tentative avec un délai exponentiel backoff permet de mieux récupérer ces conditions d'erreur.

```groovy linenums="1"
process FOO {
    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    script:
    '''
    your_command --here
    '''
}
```

## Allocation dynamique des ressources

Il est très fréquent que différentes instances d'un même processus aient des besoins très différents en termes de ressources informatiques. Dans de telles situations, le fait de demander, par exemple, une quantité de mémoire trop faible entraînera l'échec de certaines tâches. Au contraire, l'utilisation d'une limite plus élevée qui correspond à toutes les tâches de votre exécution pourrait réduire de manière significative la priorité d'exécution de votre travail dans un système d'ordonnancement.

Pour gérer ce cas d'utilisation, vous pouvez utiliser une stratégie d'erreur `retry` et augmenter les ressources informatiques allouées par la tâche à chaque _attempt_ successif.

```groovy linenums="1"
process FOO {
    cpus 4
    memory { 2.GB * task.attempt } // (1)!
    time { 1.hour * task.attempt } // (2)!
    errorStrategy { task.exitStatus == 140 ? 'retry' : 'terminate' } // (3)!
    maxRetries 3 // (4)!

    script:
    """
    your_command --cpus $task.cpus --mem $task.memory
    """
}
```

1. La mémoire est définie de manière dynamique, la première tentative étant de 2 Go, la seconde de 4 Go, etc.
2. La hauteur du temps d'exécution est également défini de manière dynamique, la première tentative d'exécution est fixée à 1 heure, la seconde à 2 heures, etc.
3. Si la tâche renvoie un statut de sortie égal à `140`, la stratégie d'erreur sera `retry`, sinon elle mettra fin à l'exécution.
4. Elle réessayera l'exécution du processus jusqu'à trois fois.
