# Sultan

### An Open edX Remote Devstack by Appsembler

This toolkit helps your run devstack on cloud (currently GCP). It will also provide the necessary tools to develop locally and run on cloud.

The ultimate goal of this toolkit is to help you running projects under development on the cloud while having the luxury to run the engineering on your machine. No dependencies headaches anymore. 

Some available and ready-to-use devstack images are going to help you running the project in a couple of minutes. You can write, delete, and start from scratch anytime with no regrets.

## Documentation
An extensive documentation on the architecture and toolkit can be found in the repo's wiki page [here](https://github.com/appsembler/sultan/wiki).

## Quick Start
To create an in-cloud devstack for yourself, you need the following instructions.

```Shell
$ git clone git@github.com:appsembler/sultan.git
$ cd sultan
$ make environment.create
## Change SSH_KEY, PROJECT_ID, SERVICE_ACCOUNT_EMAIL, SERVICE_KEY_PATH in the created .configs.<username> file
$ make instance.setup
```

> You might need to configre GCloud on your machine to set the variables above.

To run the devstack
```shell
$ make devstack.run
```

To verify that your devstack is running:
```shell
$ make instance.ping  ## Verifies that your instance is reachable.
$ curl -I edx.devstack.lms:18010  ## Curls your LMS site.
```

To stop the devstack
```shell
$ make devstack.stop
```

To stop the instance server
```shell
$ make instance.stop
```

To remove the instance
```shell
$ make instance.delete
```

> The instance is secured behind a firewall that only identifies your IP. If your IP happened to change (after a network disconnection for example), run `make instance.restrict` to change your IP in the firewall rule.


## Development
There are so many ways you can choose from to interact with a remote code. However, we recommend two common methods that ensures security, real-time transfer, and immediate reflection:

### SSHFS
We implicitly implemented this functionality within the toolkit. To use it all you have to do is to  run `make devstack.mount` and then open your favorite text editor and start editing the files on the server from your machine.

### Prefered IDEs
Some IDEs gives you the power to edit code on remote machines. [Visual Studio Code](https://code.visualstudio.com) for example, recently added [Code Remote Extensions](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack). With this extension, you'll be able to open any folder on your remote machine and take advantage of VS Code's full feature set.

## Creating an image
To create an image from your running devstack, use the following
```shell
$ make image.create
```
To create an instance from your image
```shell
$ make instance.setup.image
```

## Environment files
We create a specific ignored .configs file for you run `make environment.create`, to debug the final environment variables values you can run
```shell
$ make environment.debug
```

## Target help
To check the targets documentation run
```shell
$ make help
```

