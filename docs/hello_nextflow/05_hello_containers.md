# Part 5: Hello Containers

In Parts X-Y, you learned how to use the basic building blocks of Nextflow to assemble a simple pipeline capable of processing some text and parallelizing execution if there were multiple inputs.

However, you were limited to basic UNIX tools available in your environment.
Real-world tasks often require various tools and packages not included by default.
Typically, you'd need to install these tools, manage their dependencies, and resolve any conflicts.

That is all very tedious and annoying, so we're going to show you how to use **containers** to solve this problem much more conveniently.

!!! Note

    We'll be teaching this using the technology [Docker](https://www.docker.com/get-started/), but Nextflow supports [several other container technologies](https://www.nextflow.io/docs/latest/container.html#) as well.

---

## 0. Warmup: Pull the container image

A **container** is a lightweight, standalone, executable unit of software created from a container **image** that includes everything needed to run an application including code, system libraries and settings.
To use a container you usually download or "pull" a container image from a container registry, and then run the container image to create a container instance.

Let's pull a container image that contains the `cowsay` command so we can use it to display some text in a fun way.

```bash
docker pull 'community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65'
```

[TODO] SEGUE

---

## 1. Use a container directly (one-off)

[TODO] EXPLAIN USE CASE

### 1.1 Use the container to execute a single command

The `docker run` command is used to spin up a container instance from a container image and execute a command in it.
The `--rm` flag tells Docker to remove the container instance after the command has completed.

```bash
docker run --rm 'community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65' cowsay -t "Hello World"
```

```console title="Output"
 _____________
< Hello World >
 -------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

[TODO] EXPLAIN WHAT HAPPENED

### Takeaway

You know how to pull a container and run it directly in the terminal as a one-off execution.

### What's next?

[TODO] UPDATE LEARN TO RUN INTERACTIVELY

---

## 2. Use a container interactively

You can also run a container interactively, which will give you a shell prompt inside the container.

### 2.1. Spin up the container

[TODO] INSTRUCTION

```bash
docker run --rm -it 'community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65' /bin/bash
```

Notice that the prompt has changed to `(base) root@b645838b3314:/tmp#`, which indicates that you are now inside the container.
If we run:

```console title="Output"
(base) root@b645838b3314:/tmp# ls /
bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var
```

You can see that the filesystem inside the container is different from the filesystem on your host system.

### 2.2. Run the desired tool command

Now that you are inside the container, you can run the `cowsay` command directly.

!!! Tip

    Us the '-c' flag to pick a different "cow" from this list:
    `beavis`, `cheese`, `cow`, `daemon`, `dragon`, `fox`, `ghostbusters`, `kitty`, `meow`, `miki`, `milk`, `octopus`, `pig`, `stegosaurus`, `stimpy`, `trex`, `turkey`, `turtle`, `tux`

```bash
cowsay -t "Hello World" -c tux
```

Output:

```console title="Output"
  ___________
| Hello World |
  ===========
                \
                 \
                  \
                   .--.
                  |o_o |
                  |:_/ |
                 //   \ \
                (|     | )
               /'\_   _/`\
               \___)=(___/
```

### 2.3. Exit the container

To exit the container, you can type `exit` at the prompt or use the ++ctrl+d++ keyboard shortcut.

```bash
exit
```

Your prompt should now be back to what it was before you started the container.

### 2.4. Mounting data into containers

When you run a container, it is isolated from the host system by default.
This means that the container can't access any files on the host system unless you explicitly tell it to.
One way to do this is to **mount** a **volume** from the host system into the container.

Prior to working on the next task, confirm that you are in the `hello-nextflow` directory. The last part of the path shown when you type `pwd` should be `hello-nextflow`.

Then run:

```bash
docker run --rm -it -v $(pwd)/containers/data:/data 'community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65' /bin/bash
```

Let's explore the contents of the container.
Note that we need to navigate to the `/data` directory inside the container to see the contents of the `data` directory on the host system.

```console title="Output"
(base) root@08dd2d3efbd4:/tmp# ls
conda.yml  environment.lock
(base) root@08dd2d3efbd4:/tmp# cd /data
(base) root@08dd2d3efbd4:/data# ls
greetings.csv  pioneers.csv
```

### 2.5. Use the mounted data

Now that we have mounted the `data` directory into the container, we can use the `cowsay` command to display the contents of the `greetings.csv` file.
To do this we'll use the syntax `-t "$(cat data/greetings.csv)"` to output the contents of the file into the `cowsay` command.

```bash
cowsay -t "$(cat /data/greetings.csv)" -c pig
```

Output:

```console title="Output"
  __________________
| Hello,Bonjour,Holà |
  ==================
                  \
                   \
                    \
                     \
                               ,.
                              (_|,.
                              ,' /, )_______   _
                          __j o``-'        `.'-)'
                          (")                 \'
                          `-j                |
                            `-._(           /
                               |_\  |--^.  /
                              /_]'|_| /_)_/
                                  /_]'  /_]'
```

Now exit the container once again:

```bash
exit
```

### Takeaway

You know how to pull a container and run it interactively, make your data accessible to it, which lets you try commands without having to install any software on your system.

### What's next?

[TODO] UPDATE USE CONTAINERS IN NF WORKFLOW

---

## 3. Use containers in Nextflow

Nextflow has built-in support for running processes inside containers to let you run tools you don't have installed in your compute environment.
This means that you can use any container image you like to run your processes, and Nextflow will take care of pulling the image, mounting the data, and running the process inside it.

[TODO] [Update this to add a cowsay step to the hello-world pipeline (just add it after the uppercase step) -- include passing in the character as a parameter]

### 3.1. Write a `cowsay` module [TODO] UPDATE

[TODO] UPDATE TO GRAFT THIS ONTO THE MODULARIZED HELLO WORKFLOW

Edit the `hello-containers.nf` script to add the `cowsay` module.

_Before:_

```groovy title="hello-containers.nf"
process cowSay {

    publishDir 'containers/results', mode: 'copy'
```

_After:_

```groovy title="hello-containers.nf"
process cowSay {

    publishDir 'containers/results', mode: 'copy'
    container 'community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65'
```

### 3.2. Import the `cowsay` module into the workflow [TODO] UPDATE

[TODO]

### 3.3. Connect the `cowsay` process to the workflow [TODO] UPDATE

[TODO]

### 3.4. Run the workflow

Run the script to see the container in action.

```bash
nextflow run hello-containers.nf
```

!!! NOTE [TODO] MAYBE CHANGE THIS TO USE `-with-docker` AND INTRODUCE CONFIG IN NEXT SECTION

    The `nextflow.config` in our current working directory contains `docker.enabled = true`, which tells Nextflow to use Docker to run processes.
    Without that configuration we would have to specify the `-with-docker` flag when running the script.

You should see a new directory called `containers/results` that contains the output of the `cowsay` process.

```console title="containers/results/cowsay-output-Bonjour.txt"
  _______
| Bonjour |
  =======
       \
        \
          ^__^
          (oo)\_______
          (__)\       )\/\
              ||----w |
              ||     ||
```

### 3.5. Inspect how Nextflow launched the containerized task

Let's take a look at the task directory for one of the cowsay tasks to see how Nextflow works with containers under the hood.

Check the output from your `nextflow run` command to find the task ID for the `cowsay` process.
Then check out the task directory for that task.

```bash
tree -a work/8c/738ac55b80e7b6170aa84a68412454
work/8c/738ac55b80e7b6170aa84a68412454
├── .command.begin
├── .command.err
├── .command.log
├── .command.out
├── .command.run
├── .command.sh
├── .exitcode
├── cowsay-output-Bonjour.txt
└── output-Bonjour.txt -> /workspace/gitpod/nf-training/hello-nextflow/work/0e/e96c123cb7ae9ff7b7bed1c5444009/output-Bonjour.txt

1 directory, 9 files
```

Open the `.command.run` file which holds all the busywork that Nextflow does under the hood.

```bash
code work/8c/738ac55b80e7b6170aa84a68412454/.command.run
```

Search for `nxf_launch` and you should see something like this:

```bash
nxf_launch() {
    docker run -i --cpu-shares 1024 -e "NXF_TASK_WORKDIR" -v /workspace/gitpod/nf-training/hello-nextflow/work:/workspace/gitpod/nf-training/hello-nextflow/work -w "$NXF_TASK_WORKDIR" --name $NXF_BOXID community.wave.seqera.io/library/pip_cowsay:131d6a1b707a8e65 /bin/bash -ue /workspace/gitpod/nf-training/hello-nextflow/work/8c/738ac55b80e7b6170aa84a68412454/.command.sh
}
```

As you can see, Nextflow is using the `docker run` command to launch the task.
It also mounts the task's working directory into the container, sets the working directory inside the container to the task's working directory, and runs our templated bash script in the `.command.sh` file.
All the hard work we learned about in the previous sections is done for us by Nextflow!

### Takeaway

You know how to use containers in Nextflow to run processes.

### What's next?

[TODO] CONFIGURE STUFF
