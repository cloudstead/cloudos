cloudos
=======

An uber-repository that includes everything needed to launch cloudos instances

## Prerequisites

Java 7, maven 3, and appropriate permissions to checkout git repos

## Installing from scratch

    . setenv.sh                   # set up your shell environment
    ./first_time_dev_setup.sh     # setup git submodules, install cobbzilla-parent pom


## Building

Build *everything*:

    mvn -DskipTests=true -P complete install

To build only the cloudstead code (exclude the libraries that rarely change), just drop the `-P complete` and run this from the top-level cloudstead-uber directory:

    mvn -DskipTests=true install

To build a single module, just cd into its directory run the above command.

## Preparing for a deploy

run `./prep.sh <target>`

for example `./prep.sh you@example.com:/usr/local/apache2/htdocs/tmp/`

This will:

* Build the tarball for the cloudos-server
* Build the app bundles in cloudos-apps
* scp them to a place where they can be publicly accessed (for example when running chef-solo or installing an app)
