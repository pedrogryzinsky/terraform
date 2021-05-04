# Infrastructure Docs (idocs)

This repository implements both infrastructure documentation, assets and configuration files.

The documentation is written using [LaTeX](https://www.latex-project.org/).

Configuration files are provided using [Terraform](https://www.terraform.io/).

For further information, keep reading this documentation.

## Structure and Work

The main folders available for this repository are:

* .devcontainer: Contains all configuration required for running VS Code Remote Containers;
* .vscode: Contains VS Code specific settings;
* assets: Contains images, files and other assets required for viewing or managing the infrastructure;
* docs: Contains .tex files which combined produce the documentation;

Other important files are:

* README.md: **you're here**.
* Dockerfile: Describes how VS Code Remote Containers are built;
* this.code-workspace: Open this with VS Code to get extension suggestions;

Our recommendation for working with this repo is to open the `this.code-workspace` file with the remote container extension
using `Ctrl + Shift + P` and searching for the `Remote-Containers: Open Workspace in Container...` option.

## LaTeX

The following section describes how to develop and write with LaTeX in this project, while also providing
suggestions for users running on Windows.

### Development

The easiest way to run this project is to install Docker and use [Visual Studio Code Remote Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

This will start a development environment with Docker and Docker Compose, while also installing required extensions to work properly, such as [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop).

It pretty much works flawlessly and independent of environment. On Windows you can also run directly using WSL (Windows Subsystem for Linux). To do so, you should follow instructions [in here](https://github.com/James-Yu/LaTeX-Workshop/wiki/Install#using-wsl).

If you prefer doing things manually, you can use any TeX scheme and compiler.

### Build

To build using Docker, try: `Ctrl + Shift + P` (Command Pallette) and search for `LaTeX Workshop: Build LaTeX Project` or run `Ctrl + Alt + B`.

## Terraform

Terraform provides configuration files for the infrastructure itself. Defining infrastructure as code has a lot of advantages.

This model enables infrastructure changes to be reviewed, which allow changes to be inspected by third parties
easily, while promoting knowledge across team members. It also provides a higher level of understanding about the infrastructure itself,
as modules describe how chunks of infrastructure interact with one another.

The following sections explain how to deploy and use Terraform inside this project.
