# Setting up a development environment

## Prerequisites
* git
* java 7
* maven 3
* PostgreSQL 9.x
* node
* npm
* lineman
* VirtualBox

If you're running on Ubuntu, you can install the prerequisites with:

    sudo apt-get update
    sudo apt-get install -y git openjdk-7-jdk maven postgresql node npm 
    sudo npm install -g lineman

You'll also need to make sure a few other first-time-only things are attended to:

    # If node is missing but nodejs is there, symlink to that
    if [ ! -f /usr/bin/node ] ; then sudo ln -s /usr/bin/nodejs /usr/bin/node ; fi
    
## Get the source code

    git clone https://github.com/cloudstead/cloudos.git

## Installation

    cd cloudos
    ./first_time_dev_setup.sh                   # this will update all the submodules
    mvn -DskipTests=true -P complete install    # builds and installs all jars

If the last command above has an error (likely something like "OutOfMemoryError: PermGen space"), just run it again. 
It won't have as much to do the second time around and should complete. Alternatively you can adjust the 
memory settings with various options in the M2_OPTS environment variable.
 
Once you've run the install with `-P complete`, future builds can omit this flag, unless you are changing 
files outside the main cloudos modules. Look at the pom.xml in cloudstead-uber to see which modules are 
included in the complete profile.  

## Designate a staging host for packages

You will need a server that you can copy files to, and then retrieve via HTTP.

If your staging server supports ssh, run:

    /path/to/cloudstead-uber/prep.sh no-gen-sql user@host:/path/to/packages/dir
    
This will build all packages and copy them to the dir above. You will probably want to setup SSH keys for user@host so
that you're not prompted for your password to copy each package.
Also make sure the destination above is accessible via HTTP (or move them to an accessible location after copying them).
 
If your staging server does not support ssh, create a directory to hold the packages, say /opt/cloudos-packages, and run:

    /path/to/cloudstead-uber/prep.sh /opt/cloudos-packages
    
Now copy the contents of that directory (via FTP, thumb drive, or carrier pigeon) to someplace they will be accessible via HTTP.

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
