# Developing on the codebase

## Ubuntu

Run the `dev_bootstrap.sh` script
This will install required packages, create databases and DB users, and install and start the Kestrel MQ

## Other Operating Systems

Install PostgreSQL, memcached, Redis server, and Kestrel MQ. Create databases and DB users with the names: cloudos, cloudos_dns, wizard_form.
Additionally, create databases with those same names and the suffix "_test"

## The Kestrel MQ
    
The `dev_bootstrap.sh` script installs and starts the Kestrel message queue (MQ), which is needed for some of the tests.
If Kestrel is not running and you want to start it, run:

    sudo _JAVA_OPTIONS=-Djava.net.preferIPv4Stack=true ${KESTREL_HOME}/current/scripts/devel.sh &

To stop the Kestrel MQ, simply kill its PID:

     sudo kill $(ps auxwww | grep kestrel_ | grep -v grep | awk '{print $2}')
