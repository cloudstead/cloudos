# Setting up a development environment

## Get the build tools

You'll need java, git, maven, nodejs, npm, and lineman

For Ubuntu:

    sudo apt-get update
    sudo apt-get install -y git openjdk-7-jdk maven npm
    sudo ln -s /usr/bin/nodejs /usr/bin/node   # lineman looks for node here
    sudo npm install -g lineman                # lineman builds the frontend emberjs UI
    sudo rm -rf ~/tmp                          # remove temp dir owned by root
    
## Get the source code

    git clone https://github.com/cloudstead/cloudos.git # get the code
    cd cloudos
    ./first_time_dev_setup.sh                           # setup git submodules, install parent pom
    ./dev_bootstrap_ubuntu.sh                           # setup memcached, redis, databases, Kestrel MQ, and bcrypt
     
If you're not using Ubuntu, in place of the dev_bootstrap_ubuntu.sh script, you should:
* Install PostgreSQL, memcached, Redis server, Kestrel MQ, all with default installation options, running on standard ports 
* Create databases named (use PostgreSQL's createdb): cloudos, cloudos_test, cloudos_dns, cloudos_dns_test, wizard_form, and wizard_form_test 
* Create databases users with the names: cloudos, cloudos_dns, wizard_form. With their passwords the same as their username
* Install a bcrypt command line tool

### The Kestrel MQ
    
The `dev_bootstrap_ubuntu.sh` script installs and starts the Kestrel message queue (MQ), which is needed for some of the tests.
If Kestrel is not running and you want to start it, run:

    sudo _JAVA_OPTIONS=-Djava.net.preferIPv4Stack=true ${KESTREL_HOME}/current/scripts/devel.sh &

To stop the Kestrel MQ, simply kill its PID:

    sudo kill $(ps auxwww | grep kestrel_ | grep -v grep | awk '{print $2}')

## Building

Build *everything*:

    # just build it
    mvn -DskipTests=true -Dcheckstyle.skip=true -P complete install

    # run the tests too (make sure all dev tools are installed)
    # (we skip checkstyle because the utils/dyn-java library fails jclouds-enforced style checks)
    mvn -Dcheckstyle.skip=true -P complete install

To build only the cloudos code (exclude the libraries that rarely change), just drop the `-P complete` and run this from the top-level cloudstead-uber directory:

    mvn -DskipTests=true install    # or omit -DskipTests flag if you want to run tests (requires dev env)

To build a single module, just cd into its directory run the above command.

If the build has an error like "OutOfMemoryError: PermGen space", just run it again. 
It won't have as much to do the second time around and should complete. Alternatively you can adjust the 
memory settings with various options in the MAVEN_OPTS environment variable. For example `export MAVEN_OPTS=-Xmx2048m`
 
Once you've run the install with `-P complete`, future builds can omit this flag, unless you are changing 
files outside the main cloudos modules. Look at the top-level pom.xml to see which modules are 
included in the complete profile.  

## Bundle the apps

In order to setup a CloudOs instance, you'll need to push some artifacts to a server where the install process 
will fetch them.

The `prep.sh` script is used for this purpose. To prepare all the artifacts:

    cd ~/cloudos
    ./prep.sh all user@deploy-host:/path/to/htdocs/deploy/dir

You will need a server that you can copy files to, and then retrieve via HTTP.

This will build all packages and copy them to the dir above. You will probably want to setup SSH keys for user@host so
that you're not prompted for your password to copy each package.
Also make sure the destination above is accessible via HTTP (or move them to an accessible location after copying them).
 
If your staging server does not support ssh, create a directory to hold the packages, say /opt/cloudos-packages, and run:

    /path/to/cloudos/prep.sh /opt/cloudos-packages
    
Now copy the contents of that directory (via FTP, thumb drive, or carrier pigeon) to someplace they will be accessible via HTTP.

Once the artifacts have been copied to the remote host, verify you can fetch them with wget or curl:

    wget -S -O /dev/null http://deploy-host/deploy/dir/artifact.tar.gz

## Setup Supporting Services

Cloudstead and CloudOs rely on some third party services for things like SMTP relaying, DNS, cloud storage, and so on.
Many of these are swappable so you can use your own versions of these services.

Read about setting up [third party services or alternatives](thirdparty.md)

## Create a VirtualBox base instance

We'll use a copy of this instance for most of our work. So we create it once and then clone it when we want to use it.
Here's what the instance should look like:

* Install a "plain vanilla" Ubuntu 14.04 64-bit Server from the ISO
  * At least 2GB disk
  * At least 1GB memory
  * Bridged networking
* Create a UNIX user account that will have password-less sudo. I usually create a user named "ubuntu"
* To grant password-less sudo for user ubuntu, edit `/etc/sudoers` as root and add this at the bottom:
`ubuntu	ALL=(ALL) NOPASSWD: ALL`
* Allow password-less ssh access from your local account to the ubuntu user account:
`mkdir ~ubuntu/.ssh && chmod 700 ~ubuntu/.ssh`
* Copy your SSH key into `~ubuntu/.ssh/authorized_keys` (for RSA key) or `~ubuntu/.ssh/authorized_keys2` (for DSA key)
* Secure the authorized_keys file: `chmod 600 ~ubuntu/.ssh/authorized_keys*`
* Do any other setup that you will need for *every* instance. For example, I usually also install screen and setup a `~ubuntu/.screenrc` file.
* Now shutdown the instance (as root: `shutdown -h now`)
* Whenever we need a new instance, we will clone this one.

## Next step

* [Setup a CloudOs instance](cloudos.md)
