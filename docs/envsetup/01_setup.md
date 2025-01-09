# Gitpod

Gitpod is a cloud development environment for teams to efficiently and securely develop software. It can improve your developer experience by coding in a cloud development environment.

## Creating a Gitpod account

You can create a free [Gitpod](https://gitpod.io/) account using your GitLab, GitHub, or Bitbucket account.

You can create an account using the [Gitpod login page](https://gitpod.io/login/).

![Gitpod log in](img/login.png)

It is best to connect your LinkedIn account to receive a full 50 hours usage allocation.

![Gitpod log in one step](img/onestepaway.png)

After selecting your preferred editor, theme, and profile details, click continue and your account will be created and ready to use.

!!! note

    It is recommended to use the VS code editor.

## Running Gitpod

Click the following URL to run Gitpod: <https://gitpod.io/#https://github.com/nextflow-io/training>

This URL is the Nextflow training repository prefixed with `https://gitpod.io/#`.

Alternatively, you can click on the button below.

[![Open Gitpod](https://img.shields.io/badge/Gitpod-%20Open%20in%20Gitpod-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/nextflow-io/training)

If you are already logged in, your Gitpod environment will start to load.

### Explore your Gitpod IDE

After Gitpod has loaded, you should see something similar to the following:

![Gitpod welcome](img/gitpod.welcome.png)

-   **The sidebar** allows you to customize your Gitpod environment and perform basic tasks (copy, paste, open files, search, git, etc.). You can click the explorer button to see which files are in this repository.
-   **The terminal** allows you to run all the programs in the repository. For example, both `nextflow` and `docker` are installed and can be executed.
-   **The file explorer** allows you to view and edit files. Clicking on a file in the explorer will open it within the main window.
-   **The Simple Browser** lets you view the nf-training material browser (<https://training.nextflow.io/>). If you close it by accident, you can load the simple browser again by typing the following in the terminal: `gp preview https://training.nextflow.io`.

### Gitpod resources

Gitpod gives you 500 free credits per month, which is equivalent to 50 hours of free environment runtime using the standard workspace (up to 4 cores, 8 GB RAM, and 30 GB storage).

There is also a large workspace option that gives you up to 8 cores, 16GB RAM, and 50GB storage. However, the large workspace will use your free credits quicker and you will have fewer hours of access to this space.

Gitpod will time out after 30 minutes of inactivity and will save your changes for up to 2 weeks.

More information about Gitpod is available at [gitpod.io](https://www.gitpod.io).

### Reopening a Gitpod session

You can reopen an environment from <https://gitpod.io/workspaces>. Previous environments will be listed. You can select the ellipsis (three dots icon) and then select `Open` to reopen a previous environment.

If you have saved the URL for your previous Gitpod environment, you can simply open it in your browser.

Alternatively, you can open a new training workspace by following the Gitpod URL: <https://gitpod.io/#https://github.com/nextflow-io/training>

### Saving files from Gitpod to your local machine

To save any file from the explorer panel, right-click the file and select `Download`.
