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
## Change SSH_KEY, PROJECT_ID, SERVICE_ACCOUNT_EMAIL, SERVICE_KEY_PATH in the created .env.<username> file
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

## Mounting the devstack
To mount the devstack on your local machine
```shell
$ make devstack.mount
```
Or to unmont:
```shell
$make devstack.unmount
```

## Creating an image
To create an image from your running devstack, use the following
```shell
$ make instance.image.create
```
To create an instance from your image
```shell
$ make instance.setup.image
```

## Environment files
We create a specific ignored .env file for you run `make environment.create`, to debug the final environment variables values you can run
```shell
$ make environment.debug
```

## Target help
To check the targets documentation run
```shell
$ make help
```

