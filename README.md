cloudos
=======

An uber-repository that includes everything needed to launch cloudos instances.

## Launching

So you want to launch a CloudOs instance? Excellent. The basic steps are:
* Prepare external services (gather credentials for DNS, SSL, SMTP, S3 storage)
* Set up initialization files: SSL certs and JSON data bags
* Prepare a target machine
* Deploy CloudOs to target machine

## Developing on CloudOs

Start with the [basic setup](docs/developing.md) to set up a fresh development environment.

## Get the build tools

CloudOs requires the following build tools: java, git, maven, nodejs, npm, lineman

On Ubuntu:

    sudo apt-get update
    sudo apt-get install -y git openjdk-7-jdk maven npm
    sudo npm install -g lineman                # lineman builds the frontend emberjs UI
    sudo ln -s /usr/bin/nodejs /usr/bin/node   # lineman looks for node here

## Setup the code

    git clone https://github.com/cloudstead/cloudos.git # get the code
    cd cloudos
    ./first_time_dev_setup.sh                           # setup git submodules, install parent pom

If you want to run the tests, follow the steps to [set up a full development environment](developing.md)

## Build it

Build *everything*:

    mvn -DskipTests=true -P complete install   # just build it
    mvn -P complete install                    # run the tests too (make sure all dev tools are installed)

To build only the cloudos code (exclude the libraries that rarely change), just drop the `-P complete` and run this from the top-level cloudstead-uber directory:

    mvn -DskipTests=true install    # or omit -DskipTests flag if you want to run tests (requires dev env)

To build a single module, just cd into its directory run the above command.

## Prepare to launch

Run:
`./prep.sh /some/local/path`
or
`./prep.sh you@example.com:/some/remote/path`

In either case, path must be a directory.

This will:

* Build the tarball for the cloudos-server
* Build the app bundles in cloudos-apps
* copy them to the target, perhaps where they can be publicly accessed by cloudsteads that are deploying/updating apps/etc.

Now you're ready to [launch a new CloudOs instance!](cloudos.md)
