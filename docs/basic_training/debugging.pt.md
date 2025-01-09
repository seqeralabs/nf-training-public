---
title: Resolução de problemas
description: Tratamento de erros e resolução de problemas
---

# Tratamento de erros e resolução de problemas

## Depuração de erros de execução

Quando a execução de um processo termina com um status de saída diferente de zero,
o Nextflow encerra a execução e informa sobre a tarefa com falhas:

!!! info ""

    Clique no ícone :material-plus-circle: no código para ver explicações.

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

1. Uma descrição da causa do erro
2. O comando executado
3. O status de saída do comando
4. A saída padrão do comando, quando disponível
5. O erro padrão do comando
6. O diretório de trabalho do comando

Analise cuidadosamente os dados do erro, já que eles podem fornecer informações valiosas para a depuração.

Se isso não for o suficiente, use `cd` para entrar no diretório de trabalho da tarefa. Ele contem todos os arquivos necessários para reproduzir o erro de forma isolada.

O diretório de execução da tarefa possui os seguintes arquivos:

-   `.command.sh`: O script do comando.
-   `.command.run`: Um wrapper do comando usado para executar a tarefa.
-   `.command.out`: A saída padrão completa da tarefa.
-   `.command.err`: O erro padrão completo da tarefa.
-   `.command.log`: A saída do wrapper de execução.
-   `.command.begin`: Um arquivo sentinela criado no momento que a tarefa é iniciada.
-   `.exitcode`: Um arquivo contendo o código de saída da tarefa.
-   Os arquivos de entrada da tarefa (links simbólicas)
-   Os arquivos de saída da tarefa

Certifique-se que o arquivo `.command.sh` contém o comando esperado e que todas as variáveis
foram substituídas pelos valores desejados.

Também verifique a existência dos arquivos `.exitcode` e `.command.begin`, que, se ausentes, sugerem que a tarefa nunca foi executada pelo subsistema (o escalonador de lotes, por exemplo). Se o arquivo `.command.begin` existir, a tarefa foi iniciada mas foi provavelmente encerrada abruptamente.

Para verificar a causa do erro, você pode replicar a execução com falhas usando `bash .command.run`.

## Ignorando erros

Existem casos em que um erro em um processo é esperado e não deve encerrar a execução do fluxo de trabalho.

Para lidar com isso, forneça o valor `ignore` a `errorStrategy`:

```groovy linenums="1"
process FOO {
    errorStrategy 'ignore'

    script:
    """
    seu_comando --isso --aquilo
    """
}
```

Se você deseja ignorar qualquer erro, você pode especificar a mesma diretiva em um arquivo de configuração:

```groovy
process.errorStrategy = 'ignore'
```

## Tolerância automática a falhas

Em casos mais raros, erros podem surgir por causa de condições transitórias. Nessas situações, uma estratégia eficaz é re-executar a tarefa com falhas.

```groovy linenums="1"
process FOO {
    errorStrategy 'retry'

    script:
    """
    seu_comando --isso --aquilo
    """
}
```

Ao usar a estratégia de erro `retry` a tarefa é re-executada uma segunda vez se ela retornar um status de saída diferente de zero antes de encerrar a execução completa do fluxo de trabalho.

A diretiva [maxRetries](https://www.nextflow.io/docs/latest/process.html#maxretries) pode ser utilizada para configurar o número de tentativas que uma tarefa pode ser re-executada antes de declarar que ela falhou com uma condição de erro.

## Re-execução com atraso

Existem casos em que os recursos necessários para a execução estão temporariamente indisponíveis (por exemplo, congestionamento de rede). Nesses casos apenas re-executar a tarefa provavelmente levará a um erro idêntico. Uma re-execução com um atraso exponencial pode contribuir de uma melhor forma para a resolução desses erros.

```groovy linenums="1"
process FOO {
    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    script:
    '''
    seu_comando --aqui
    '''
}
```

## Alocação dinâmica de recursos

Uma situação bastante comum é que diferentes instâncias de um mesmo processo podem ter necessidades diferentes de recursos computacionais. Nessas situações, solicitar uma quantidade de memória muito baixa, por exemplo, irá levar algumas tarefas a falharem. Por outro lado, usar um limite mais elevado que abrange todas as suas tarefas pode reduzir significativamente a prioridade de execução delas em um sistema de escalonamento de tarefas.

Para lidar com isso, você pode utilizar uma estratégia de erro `retry` e aumentar os recursos computacionais alocados pela tarefa em cada _tentativa_ consecutiva.

```groovy linenums="1"
process FOO {
    cpus 4
    memory { 2.GB * task.attempt } // (1)!
    time { 1.hour * task.attempt } // (2)!
    errorStrategy { task.exitStatus == 140 ? 'retry' : 'terminate' } // (3)!
    maxRetries 3 // (4)!

    script:
    """
    seu_comando --cpus $task.cpus --mem $task.memory
    """
}
```

1. A memória é definida de forma dinâmica, a primeira tentativa é com 2 GB, a segunda com 4 GB, e assim sucessivamente.
2. O tempo de execução da tarefa é configurado dinamicamente também, a primeira tentativa é com 1 hora, a segunda com 2 horas, e assim sucessivamente.
3. Se a tarefa retorna um status de saída igual a `140` a estratégia de erro será `retry`, caso contrário, a execução será encerrada.
4. O processo será re-executado até três vezes.
