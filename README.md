# Sultan [![Sultan Tests](https://github.com/appsembler/sultan/actions/workflows/test.yml/badge.svg?event=push)](https://github.com/appsembler/sultan/actions/workflows/test.yml)

### An Open edX Remote Devstack by Appsembler

This toolkit helps your run devstack on cloud (currently GCP). It will also provide you with the necessary tools to help you using your local machine for development, and your cloud instance for showing and testing.

The ultimate goal of this toolkit is to help you running projects under development on the cloud while having the luxury to run the engineering side on your machine. No dependencies headaches anymore. 

Some available and ready-to-use devstack images are going to help you running the project in a couple of minutes. You can write, delete, and start from scratch anytime with no regrets.

## Documentation
An extensive documentation on the architecture and the toolkit commands can be found in the repo's wiki page [here](https://github.com/appsembler/sultan/wiki).

Appsembler Internal Doc [here](https://appsembler.atlassian.net/wiki/spaces/~869427582/pages/1556250675/Sultan+Appsembler).

## 1. Before you start
- Make sure you have your SSH key added into our GCP Appsembler Devstack (appsembler-devstack-30) project. You can check that at GCP [Compute Metadata](https://console.cloud.google.com/compute/metadata/sshKeys?project=appsembler-devstack-30).
- Make sure you have [GCloud command-line tools](https://cloud.google.com/sdk/docs/install) installed.
- Make sure you have a working python 3.7 environment. 

## 2. Quick Start

### 2.1. Clone and configure
If you're on Linux, follow the next steps to set up your Sultan devstack

```console
$ git clone git@github.com:appsembler/sultan.git
$ cd sultan
$ sultan config init  # Make sure you're in the correct python environment, this will install the required package immediatly one you run it.
## configs/.configs.username is created
```

If you're on macOS, follow the steps to set up your Sultan devstack

```console
$ git clone git@github.com:appsembler/sultan.git
$ cd sultan
$ ./sultan config init
```

> **NOTE**
>
> All the generated files will exist in `$SULTAN_HOME`, you can change the value of this from you configurations file.


### 2.2. Required configurations
The following configurations must be overridden in your recently-created config 
file: 

* `SSH_KEY`: The private key that has access to the GCP project where we will 
create your instance
* `PROJECT_ID`: The GCloud project ID.
* `SERVICE_ACCOUNT_EMAIL`: A string that we will use to create a service account. 
* `SERVICE_KEY_PATH`: Path to the service account key created in the steps above. 

More about this later in [Working with configurations](#3-working-with-configurations)
section.

### 2.3. Create your first devstack
Create an instance from a pre-packaged image

```console
$ sultan instance setup --image devstack-juniper
```

## 3. Working with configurations

### 3.1. Local environment set up
To setup the configurations on your local machine, we need to make sure that 
your local environment is correctly set up.

1. You'll need to create a service account in the GCloud project that will host 
your devstack instance (official docs [here](https://cloud.google.com/iam/docs/creating-managing-service-accounts)).
1. Grant the service account permission to create an instance (official 
docs [here](https://cloud.google.com/iam/docs/granting-roles-to-service-accounts#granting_access_to_a_service_account_for_a_resource)). 
1. Grant the service account `roles/compute.instanceAdmin` role (See also 
the [list of roles](https://cloud.google.com/sdk/gcloud/reference/iam/roles/list)).
1. Download the service account on your machine.

### 3.2. Getting sultan configurations ready
1. After downloading the service account, edit the value of `SERVICE_KEY_PATH` 
to match its location. (Follow the official docs ([here](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)) 
to generate a key for your service account).
1. Edit (uncomment, set) the following values in your configs file

```shell
## File configs/.configs.$USER
SSH_KEY="$(HOME)/.ssh/id_rsa"
PROJECT_ID=<gcp-project-id>
SERVICE_ACCOUNT_EMAIL=email@<gcp-project-id>.iam.gserviceaccount.com
SERVICE_KEY_PATH=/path/to/service/key.json
```

> **NOTE**
>
> - This example has my values
> - You should change the value `SERVICE_KEY_PATH` if you decided to copy and 
> paste the configurations above.

### 3.3. Optional configurations

#### Preemptible machine
Preemptible VMs are highly affordable, short-lived compute instances suitable 
for fault-tolerant workloads. They offer the same machine types and options as 
regular compute instances and last for up to 24 hours, and can reduce your 
Compute Engine costs by up to 80%!

Sultan allows you to setup a preemptible machine, you can do that by setting
the configuration variable `PREEMPTIBLE` to `true`. Just something to note 
here, preemptible machines are not suitable for long provisioning work, we only 
recommend using them with `sultan instance setup --image` command. If you 
noticed a freeze in your machine's shell, it means that your machine got 
interrupted, and you might have to restart the session again.

#### Machine lifespan
When you create a sultan instance, the instance will be configured to run for 
a specific amount of time configured in `ALIVE_TIME` in the configurations 
file. We sat the default lifespan to 6 hours, when your machine powers off
you can start it again using 
```
$ sultan instance start
```

To stop the machine manually before the timeout use
```shell
$ sultan instance stop
```

#### Exposed ports
For security reasons, Sultan firewall will restrict access to the ports in
`EXPOSED_PORTS` in your .configs file. Here's the full list of the ports you
might want to enable.

> **NOTE**
>
> You need to run `sultan instance restrict` everytime you change the port.


| Service                          | Port  | Role    |
|----------------------------------|-------|---------|
| `ssh`                            | 22    | Machine |
| `lms`                            | 18000 | Default |
| `studio`                         | 18010 | Default |
| `forum`                          | 44567 | Default |
| `amc`                            | 22    | Extra   |
| `discovery`                      | 18381 | Default |
| `ecommerce`                      | 18130 | Default |
| `credentials`                    | 18150 | Default |
| `edx_notes_api`                  | 18120 | Default |
| `frontend-app-publisher`         | 18400 | Default |
| `gradebook`                      | 1994  | Default |
| `registrar`                      | 18734 | Extra   |
| `program-console`                | 1976  | Extra   |
| `frontend-app-learning`          | 2000  | Extra   |
| `frontend-app-library-authoring` | 3001  | Extra   |
| `course-authoring`               | 2001  | Extra   |
| `xqueue`                         | 18040 | Extra   |

#### Accessing `sultan` from any directory on your machine 
If you want to access `sultan` command line from any directory, add this repo 
dir to your `PATH`
```console
$ export PATH=$PATH:$(pwd)  # pwd should translate to /path/to/projects/sultan
```

#### Enabling auto completion 
To enable auto completion
```console
$ source extras/sultan-completion.bash  # For bash shell
$ source extras/sultan-completion.zsh   # For zsh shell
```

> **NOTE**
>
> You can add the command above to your ~/.bashrc or ~/.zshrc

#### Check the best zone for your machine
This is in order to have as small latency to your machine and mounted dirs as 
possible. You can check it here: http://www.gcping.com/ Following example will 
be how I’ve set it up (the ZONE value) in Europe.

For minimum latency. You can set `ZONE` value to match the nearest GCP zone to 
you.
```shell
## File configs/.configs.$USER
ZONE=europe-west3-c
```

#### Debugging
If this is your first time creating your instance, we recommend 
enabling `DEBUG` mode to be able to to see a verbose output in case something 
fails:
```shell
## File configs/.configs.$USER
DEBUG=false
```

#### Devstack run command
We created a custom env variable for the devstack run command. EdX 
uses `dev.up` to get the devstack services running. However, in Appsembler we
use some other services that requires extra environment variables such as 
`HOST`. So simply what we can do here is
```
## File configs/.configs.$USER
DEVSTACK_RUN_COMMAND="HOST=tahoe dev.up"
```

> **NOTE**
>
> You need to configure GCloud on your machine before setting the variables
> above.

## 4. Creating your first edX devstack instance

### 4.1. Setting up the devstack
Simple as running
```console
$ IMAGE_NAME=devstack-juniper  # Or any other devstack image name
$ sultan instance setup --image $IMAGE_NAME
```

The previous command will spin an instance for you from an already created 
image. However, if you prefer to run the full setup from scratch just don't
supply an `image` argument. 

```console
$ sultan instance setup
```

Make yourself some coffee. Go for a jog. Recreate the Sistine Chapel painting.
Actually, go and built the chapel first. Then do the painting. You’ll have 
time. A full setup takes quite long. But, once it’s finished…


### 4.2. Bring up devstack up
To run the devstack
```console
$ sultan devstack up
```

It works. Noice!!

#### Verify everything is reachable
To verify that your instance has been created:
```console
$ sultan instance status  ## Prints your GCP instance status.
$ sultan instance ip  ## Shows you the instance IP.
$ sultan instance ping  ## Verifies that Ansible is able to reach your instance.
```
To verify that your devstack is running:
```console
$ curl -I devstack.tahoe:18010  ## Curls your Studio site.
```

> **NOTE**
>
> LMS and Studio might take up to 3 minutes to fully spin. You can check their
> logs by running `sultan devstack make lms-logs`. 

#### Accessing the default created LMS site, Studio, edx admin

Our Devstack automatically creates your initial site:

| Property  | Value           |
|:----------|:----------------|
| LMS Port  | 18000           |
| Username  | red             |
| Email     | red@example.com |
| Password  | red             |


Other information:

| Property                 | Value                       |
|:-------------------------|:----------------------------|
| Studio Port              | 18010                       |
| EDX admin username       | edx                         |
| EDX admin password       | edx                         |


### 4.3. Everything works, you’re happy? SAVE IT.

Once you’ve got everything set up the way you like it and it’s working 
super-duper, you’ll want to save this sweet sweet and highly unlikely state of 
our glorious Devstack. To do that you want to create an image of your VM so you 
can redeploy it quickly whenever you (inevitably) break your Devstack.

In order to do so, simply run:

```console
$ sultan image create
```

You can also specify a name for your image using
```console
$ sultan image create --name my-lovely-image
```

> **NOTE**
>
> Just don't forget to supply the image name later to the `setup` command when
> you wanna retrieve it: `sultan instance setup --image my-lovely-image`.


### 4.4. Starting/stopping your Devstack

To start your Devstack once it’s set up:
```console
$ sultan instance start
## beep-boop the machine does some machine stuff
$ sultan devstack up
```

Stopping? No problem
```console
$ sultan instance stop  ## Will stop your devstack firts, then the instance.
```

Want to get rid of it?
```console
$ sultan instance delete
```


#### OMG IT FAILS I CANNOT ACCESS MY INSTANCE. BAD DEVSTACK BAD!

It’s most likely a firewall issue. The instance is secured behind a firewall 
that only identifies your IP. Probably your IP happened to change (after a 
network disconnection for example). Here’s the remedy:

- If you didn’t already, do the `sultan instance start`
- Try reaching it with `sultan instnace ping`
- if it cannot reach it, do the `sultan instance restrict` to adjust the firewall rule.

I’m just gonna assume it worked and you self-high-fived.


#### YOU LIED! IT STILL DOESN’T WORK!
Huh, could be something’s properly broken. But remember when we created the 
image of your instance?

```console
$ sultan instance setup --image
```

> **NOTE**
>
> If you don't supply an image name to this command, `sultan` will default back
> to the `IMAGE_NAME` value set in your configs file. So all is good.

Woah it’s so fast I cannot believe it!
Yup, really works fast and resets it to that glorious state you saved. Nice.

> **NOTE**
>
> The instance is secured behind a firewall by default. To override this 
> behavior, change `RESTRICT_INSTANCE` value in your configs to `false`. 

## 5. Development
To change or update edx-platform code from your machine and reflect on the 
server immediately, there are so many ways you can choose from. However, we 
recommend two common methods to ensure security, real-time transfer, and 
immediate reflection on the remote instance:

### 5.1. SSHFS
To use it all you have to do is to  run `sultan devstack mount` and then open 
your favorite text editor and start editing files on the server from your 
machine.

### 5.2. Preferred IDEs
Some IDEs gives you the power to edit code on remote 
machines. [Visual Studio Code](https://code.visualstudio.com) for example, 
recently added [Code Remote Extensions](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack). 
With this extension, you'll be able to open any folder on your remote machine 
and take advantage of VS Code's full feature set.


> **NOTE**
>
> If you are using MacOS, make sure to install [osxfuse](https://osxfuse.github.io/)
> and giving it the right permissions before running `sultan devstack mount`.


If you at a later point restart or whatever without unmounting first and it 
doesn’t work, just do `sultan devstack unmount` and then 
again `sultan devstack mount`. Works like a charm.

> **DISCLAIMER**
>
> Manually mounting your devstack locally is slow and laggy. Barely usable. 
> But what I’ve found is that it works way way better with Visual Studio Code 
> and its Code Remote Extensions.

## 6. Configurations variables
We create a specific ignored .configs file for you when you ran `sultan config init`, 
to debug the interpreted values of your configs that sultan reads you can run
```console
$ sultan config debug
```

## 7. Tool help
To check sultan commands' documentation run
```console
$ sultan -h
$ sultan --help
```

## 8. CI/CD
This repo is now being used to ensure our edX services work under our devstack
expectations.

All CI/CD is currently done on GitHub. CD will run everytime we have a build 
triggered from the master branch on Sultan.

## 9. Errors
Errors are possible all the time. If an error's fired while executing commands 
from this toolkit it is recommended to do a little bit more debugging.
While this might be an issue with the tool, we just want you to make sure that 
you have everything correct set up in place:
* Run `sultan config debug` and check if all of your environment variables hold the correct values.
* Enable out debugging through the `DEBUG` setting in your env file.
* Check our [Wiki](https://github.com/appsembler/sultan/wiki) page for a detailed documentation on the configuration process.

If you couldn't identify the cause of the problem, please submit an issue on https://github.com/appsembler/sultan/issues.

#### LMS pages show TypeError exception
##### Problem
The exception below shows up on every (or most) lms pages 
a [full example log is available in this gist](https://gist.github.com/grozdanowski/d6237342d3b693e19dfff4c43b0b1585).
```
TypeError: _clone() takes exactly 1 argument (3 given)
```
##### Instructions
Omar: While I don’t know why this happening, I know how to fix it.

Apparently, devstack installs an incorrect `django-model-utils` package that 
breaks the LMS. Install a specific version of `jazzband/django-model-utils` so 
the platform works:
```console
$ ssh devstack
$ cd workspace/src
$ mkdir -p edxapp-pip
$ cd edxapp-pip
$ git clone https://github.com/jazzband/django-model-utils.git
$ cd django-model-utils
$ git checkout 3.0.0
$ exit
$ sultan devstack up
```

That should fix the problem.

## 9. Variables tree

```
┌── VERSION
├── EXPOSED_PORTS
├── BOOT_DISK_TYPE
├── DISK_SIZE
│                                         ┌── INVENTORY_CONFIGS_DIR ── INVENTORY
│                       ┌─── SULTAN_HOME ─┤
├──  HOME ──────────────┤                 └── MOUNT_DIR
│                       └─── SSH_KEY
│
│                       ┌─── VERBOSITY
├── DEBUG ──────────────┤
│                       └─── SHELL_OUTPUT
│
├── DEVSTACK_REPO_BRANCH ─── OPENEDX_RELEASE
│                                                             ┌── DEVSTACK_DIR
│                       ┌─── HOME_DIR ── DEVSTACK_WORKSPACE ──┤
│                       │                                     └── VIRTUAL_ENV
├── USER_NAME ──────────┤
│                       └──┐                                  ┌── ALLOW_FIREWALL
│                          │                                  ├── DENY_FIREWALL
│                          ├─────────── INSTANCE_NAME ────────┤
│                          │                                  ├── INSTANCE_TAG
│                          │                                  └── IMAGE_NAME
├── HOST_NAME ─────────────┘
├── PROJECT_ID
├── EXPOSED_PORTS
├── BOOT_DISK_TYPE
├── DISK_SIZE
├── MACHINE_TYPE
├── ZONE
├── PREEMPTIBLE
├── ALIVE_TIME
├── SSH_AGENT_HOST_NAME
├── HOSTS_FILE
├── IMAGE_FAMILY
├── EDX_HOST_NAMES
├── SERVICE_ACCOUNT_EMAIL
├── DEVSTACK_REPO_URL
├── SERVICE_KEY_PATH
├── DEVSTACK_RUN_COMMAND
├── RESTRICT_INSTANCE
├── RESTRICT_INSTANCE
├── BOLD
├── NORMAL
├── WHITE
├── RED
├── GREEN
├── YELLOW
├── BLUE
├── PURPLE
├── CYAN
├── GRAY
├── DARK
├── PINK
├── COLS
├── SULTAN_ENV
└── ETC_HOSTS_HACK
```

## 10. To conclude
Please add more stuff to this doc as you discover helpful information. Let’s 
all strive for a bright future where an engineer can follow a couple easy 
steps here and BOOM it’s done.
