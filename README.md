# Sultan

### An Open edX Remote Devstack

This toolkit helps your run devstack on cloud (currently GCP). It will also provide the necessary tools to develop locally and run on cloud.

The ultimate goal of this toolkit is to help you running projects under development on the cloud while having the luxury to run the engineering on your machine. No dependencies headaches anymore. 

Some available and ready-to-use devstack images are going to help you running the project in a couple of minutes. You can write, delete, and start from scratch anytime with no regrets.

## Components
Those components are the pillars of this solution. Each one tackles a different problem in the way of running a solution.

### Machine
Each developer can maintain only a **single** machine at a time. The machine is based on an Ubuntu 18.04 LTS image that comes with 7.5 GB of RAM and 200 GB disk space to ensure smooth read/write operations over the network.
Please note that each user can have a single machine; creating a new machine will result in deleting the previous one.

### Devstack
The devstack we are using here is the [Appsembler's Devstack](http://github.com/appsembler/devstack/) available on Github. We are not changing the behavior or patching the devstack for this toolkit to work. 

### Network
To ensure a secure environment and a reliable one, we implemented a firewall policy on all instances created using this toolkit. All instances in the devstack project have an internal and external IP address. However, each developer's instance is only accessible by her, and nobody in the team nor on the internet is allowed connect to any port on that instance.

The rules that ensure this behavior are:
```
DENY     0.0.0.0/0
ALLOW    <your.public.ip.address>
```

### SSH keys
In order to be able to access your instance and any private repo on Github, we ask for an SSH key to be available on your local machine during the deployment process. This key is expected to have access to your edx-platform Github repo and your GCP space. We are using GCP VMs to deploy your devstack on cloud.  

We are not transferring any private information between your machine and the remote machine, we will only use `AgentForwarding` here to perform the necessary operations on the remote server. 

### Images
Images here are a helpful resource for you. Maintaining an up-to-date image will help you skip the deployment and the provisioning process. Launching a new instance will be doable in a few minutes with the help of images.

We have two types of images you can start an instance from:
1. The master image which is a clean image of the [devstack](https://www.github.com/appsembler/devstack) master branch.
    > Master images are prepopulated, you don't have to create one in order to use them. 
1. A user-specific image that a developer creates while developing their application.
    > Each user is entitled to issuing/using only one user-specific-image; creating a new image of that type will result in deleting the previous one.

## Workflow
Before jumping into Let's Start section, we strongly feel you understand the workflow this toolkit is implementing and how to work with that flow to gain the most out of it.

1. You will start from within your machine. Please make sure you have access to [appsembler-devstack-30](https://console.cloud.google.com/compute/instances?project=appsembler-devstack-30&authuser=1&folder&organizationId&supportedpurview=project&instancessize=50) project in GCP.
1. In the beginning, no machines are assigned to you. The toolkit will help you creating a new machine with the specifications, and the access rules mentioned above.
1. The utility has playbooks that will help you prepare your machine, the host of the devstack.
1. After deploying the machine, you will need to provision the devstack. This will be performed automatically after the deployment is successfully done. 
1. After provisioning the devstack, you can create an image of your instance to help you skip steps 3 and 4.
1. To work on the devstack, you need to mount the volumes on your machine. The toolkit will help you do so without worrying about the technicalities.
1. during the development, you can run any command on the instance or in the devstack using the Make targets.
1. After finishing, you can just unmount the volumes and stop the servers.

Picking up from where you left is super easy using this approach, changes will be reflected instantly on the machine, and your computer is surely going to remain clean if you used the Make targets and didn't manually play with the infrastructure.

## Let's Start

### Requirements
1. A UNIX machine (Ubuntu or OsX).
1. Python.
1. [Authenticated GCloud](https://cloud.google.com/sdk/gcloud/reference/auth/login).
1. [SSHFS](https://osxfuse.github.io).
1. [FUSE](https://osxfuse.github.io) for macOS.
1. A reliable internet connection.

### Setting up the environment
#### Local configurations

- To edit the default values in `.env` file, you can create a personal copy of the `.env` file using
    ```bash
    $ make environment.create
    ```

- In the created file, there are plenty of environment variables that you can override. For example, if you have a specific `SSH_KEY` linked to your Github and your GCP space you can customize it using
    ```bash
    SSH_KEY="$(HOME)/.ssh/appsembler"
    ```
- And also, there are some environment variables that we'd rather you not to change and those are usually marked with `DON'T CHANGE` tag.

- You can check the final values of those environment variables to be used in Makefile by running
    ```bash
    $ make environment.display
    ```

#### Remote machine setup
Start by setting up the instance, the firewall rules, the local configurations, and provisioning your devstack
```bash
$ make instance.setup
```

Now we can assume that your devstack is running and accessible from you. To verify that, you can run the following commands
```bash
$ make instance.ping
$ curl -I edx.devstack.lms:18010
```

The first command is to verify that you can access the server. If it fails, there's probably an error with your Firewall configurations. The second command is more about verifying that the devstack is actually running inside your server, and that you are able to access that devstack. If the second command fails, there's probably an error with your devstack or it might not be running at all.

#### Running the devstack

After finishing the above you can run the devstack from your local machine using the following command
```bash
$ make devstack.run
```

#### Mounting the work directory
Mounting the work directory on your machine will allow you to start the development process on cloud. You can do the mounting using:
```bash
$ make devstack.mount
```

After finishing you can unmount using 
```bash
$ make devstack.unmount
```
Note that `unmount` target will stop the server as well.


### Create an image
After provisioning your instance you can create an image from your server immediately so that you don't have to repeat steps 1 to 5.

> The following commands will stop your instance if it's running and will remove any previous image if it exists.

- To create a master image:
    ```bash
    $ make instance.image.master.create
    ```

    > Master images are meant to be shipped from a clean, stable instance provisioned from the [devstack](https://www.github.com/appsembler/devstack) master branch. Please don't issue ones from a dirty instance. 

- To create a specific image for yourself:
    ```bash
    $ make instance.image.create
    ```

### Create an instance from an image
- To create an instance from the master image:
    ```bash
    $ make instance.setup.image.master
    ```

- To create an instance from a previously exported user-specific image run
    ```bash
    $ make instance.setup.image
    ```
    This command will remove the previously created instance if exists before checking the image. If you don't have an already exported image and you run this command you'll end up losing your instance for nothing.

### Reconnecting to instance after your IP changes
If your machine disconnected from the network and reconnected again, then most probably you'll end up with a different IP address that the firewall won't recognize. To overcome this issue all you have to do is:
```bash
$ make instance.restrict
```
This command is probably one of the most used commands in this toolkit as it is your gateway to interact with the server. 

### The hosts file
Usually, devstack developers are [asked](https://github.com/appsembler/devstack/#add-etchosts-entries) to modify their own `/etc/hosts` file in their system to match their docker host IP. We automatically manage this process now every time you start and stop a devstack instance.

The command that's responsible of updating your hosts file runs an Ansible script against your local machine so that it keeps track of the changes it performs there. We will revert the changes as soon as you `stop` your cloud instance.

### Start and stop the devstack
You can start the devstack without having to SSH into the server using
```bash
$ make devstack.run
```

> Note that you can hit `ctrl + c` anytime after the target finishes running the frontend server. 

To stop the devstack servers properly you can run:
 ```bash
$ make devstack.stop
```

## Effects on your local machine
Some of the commands we run here might edit some files, or change the state of some programs on your machine. To keep those effects clear, we documented them here by affected modules.

-  `/etc/hosts`: Failure to update this file with the correct values will prevent you from accessing the devstack on your remote machine. This file will be automatically updated every time you:
    - Start an instance. (`instance.start`)
    - Stop an instance. (`instance.stop`)
    - Delete an instance. (`instance.delete`)
    - Setting up an instance. (`instance.setup` or `instance.setup.image`)
- `~/.ssh/config`: Failure to update this file will prevent the toolkit from having an appropriate connection with the remote machine. This file will be automatically updated every time you:
    - Start an instance. (`instance.start`)
    - Setting up an instance. (`instance.setup` or `instance.setup.image`)
- `~/.ssh/known_hosts`: Failure to update this file will complicate the process of connecting to your remote machine using SSH and will require you to manually keep editing the file. To make this easier on you, this file will be automatically updated every time you:
    - Start an instance. (`instance.start`)
    - Setting up an instance. (`instance.setup` or `instance.setup.image`)
- `ssh-agent`: Failure to add your `$SSH_KEY` to you the `ssh-agent` will prevent your remote machine from accessing private repos on your github account and will require you to manually setup private keys on the machine. We will make sure that the record exists every time you:
    - Start an instance. (`instance.start`)
    - Setting up an instance. (`instance.setup` or `instance.setup.image`)
- `TMP_DIR`: A new directory will be created for you in the place you define in your `.env` file. This directory will hold the mounts and and any other required data we need to keep track of. An interaction with this directory will happen every time you:
    - Mount your devstack. (`devstack.mount`)
    - Unmount your devstack. (`devstack.unmount`)

## What to expect?
This project came to solve your issues when trying to start a devstack on a local machine. As the majority of these problems are environmental ones, we are allowing you here to use a unified environment that works for all team members.
- Zero interactions with GCP GUI interface.
- Environment-agnostic devstack.
- Smooth deployments and handy instance management tools.
- Clean personal machines.
- Clean setup and easy-to-use tools.
- Secure connections between you and the instance.
