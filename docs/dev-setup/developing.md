# Developing on the codebase

## Creating the databases and db users
    
    for user in $(whoami) cloudos cloudos_dns ; do
      sudo -u postgres -H createdb ${user}
      sudo -u postgres -H createuser --createdb ${user}
      sudo -u postgres -H createuser --createdb ${user}_test
      sudo -u postgres -H bash -c "echo \"alter user ${user} with password '${user}'\" | psql -U postgres" 
    done
    
    # Set passwords for db users (needed to generate schemas). 
    # If you changed the password generation above, then update the values below to match your passwords
    echo "export CLOUDOS_DB_PASS=cloudos" >> ~/.cloudos-test.env
    echo "export CLOUDOS_DNS_DB_PASS=cloudos_dns" >> ~/.cloudos-dns-test.env

