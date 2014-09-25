# Configuration Data Flows

With so much configuration information flying around, it can be hard to keep track of what gets stored where, and what things are used for. This document attempts to clarify that a bit.

----
## Registration
### actor: end user (on public website)
A registration for a new user on the public website (www.cloudstead.io) gives us:

   * email address: the cloudos instance will send an email here after it has set itself up
   * mobile phone: to be used with two-factor authentication for the account on cloudstead.io
   * password: when the user clicks on the link in the email after cloudos setup, this will be the "original password" they need to change, to set a cloudos-specific password. it's passed to the cloudos in bcrypted form, and then deleted after the password's been matched an a new one has been set.

This information is stored in the cloudstead database and can be used to launch new CloudOs instances.

----
## New CloudOs Request
### actor: end user (on public website)
On public website (www.cloudstead.io), a CloudOsRequest consists of the following:

   * name: The simple hostname (not FQDN) of the cloudOs instance

A name of "newco" would bring up a cloudstead with the hostname "newco.cloudstead.io". The domain (in this case, cloudstead.io) comes from the value of the `CLOUDOS_PARENT_DOMAIN` env var in the shell that started the cloudstead-server.

----
## Server-side CloudOs Fulfillment
### actor: cloudstead-server (public website)
When launching a cloudos instance, a cloudstead-server will:

* Creates fresh credentials for AWS (IAM user), Sendgrid, and cloudos-dns
* Create the initial databags for the instance
* Copies the databags and SSL certs the instance, and starts the chef run

*From end-user's CloudOsRequest:*

   * cloudos/init.json: base.hostname (same as name above)
   * cloudos/init.json: cloudos.recovery\_email (same as user's email at registration)

*Set at launch time by public server:*

   * cloudos/init.json: cloudos.run_as (currently hardcoded to 'cloudos')
   * cloudos/init.json: cloudos.admin\_initial\_pass (the bcrypted hash of the user's password on cloudstead.io, this will be their initial password on the cloudos instance)
   * cloudos/init.json: base.parent\_domain (set by public website, for example cloudstead.io)
   * cloudos/init.json: cloudos.aws\_iam\_user (the IAM user with perms to read/write from a subdir of the bucket. IAM username is a hash of the public-site-user-account's uuid + the cloudos name + salt)
   * cloudos/init.json: cloudos.aws\_access\_key (access key for the IAM user, with perms to read/write from a subdir of the bucket)
   * cloudos/init.json: cloudos.aws\_secret\_key (access key for the IAM user, with perms to read/write from a subdir of the bucket)
   * cloudos/init.json: cloudos.s3\_bucket (bucket where the IAM user can read/write from a subdir of the bucket that matches their IAM user name)
   * cloudos/init.json: cloudos.authy.username (API key for authy, shared among all instances, must be changed before SSH access is allowed)
   * cloudos/init.json: cloudos.dns.username (username for cloudos-dns, generated at launch-time)
   * cloudos/init.json: cloudos.dns.password (password for cloudos-dns, generated at launch-time)
   * email/init.json: smtp_relay.username (Sendgrid credentials, generated at launch-time)
   * email/init.json: smtp_relay.password (Sendgrid credentials, generated at launch-time)

*Sent as files:*

   * SSL key/cert (currently wildcard key/cert - later we will generate individual certs for each instance, currently must be changed before SSH access is allowed)

----
## CloudOs Setup
### actor: cloudos-chef (on cloudos instance)
When chef-solo runs, it uses the above config as follows:

  * cloudos/init.json: base.hostname -- along with parent\_domain, determines the FQDN of the machine
  * cloudos/init.json: base.parent_domain -- along with hostname, determines the FQDN of the machine
  * cloudos/init.json: cloudos.run\_as -- this is the unix user that the java server will run as
  * cloudos/init.json: cloudos.recovery\_email -- see below, upon successful chef run, a setup link is sent to this address. it is also saved to ~/.first\_time\_setup (deleted after setup)
  * cloudos/init.json: cloudos.admin\_initial\_pass -- saved in ~/.first\_time\_setup (after the user changes their password at first-time setup, this file is deleted)

*The following are written to ~/.cloudos.env (sourced by jrun when launching the java server):*

  * cloudos/init.json: cloudos.aws_iam_user, aws_access_key, aws_secret_key, s3_bucket, cloudos.authy.username, cloudos.dns.username, cloudos.dns.password

----
## CloudOs Setup: Java Server Configuration
### actor: cloudos-server (on cloudos instance)
When the java server runs, jrun sources ~/.cloudos.env
In the listing below, most variables are taken verbatim from cloudos-init.json (written to ~/.cloudos.env at chef-time as a template resource)
The exceptions are:
* fqdn = base.hostname + "." + base.parent_domain
* data_key = generated randomly on the host

#### How the config is made accessible to code running within the Java server
The ~/.cloudos.env file is used to substitute environment variables into api-config.yml (jar: /api-config.yml, source: src/main/resources). This yaml file is read in when the Java server starts, and populates an instance of the McApiConfiguration class, which is then exposed as a Spring bean.

    # If we need to display/email a URL back to ourselves, this is what it starts with
    export PUBLIC_BASE_URI=https://<%=@fqdn%>
    
    # Will ultimately come from data bag
    export APPSTORE_BASE_URI=https://localhost:8080
    
    # Uncomment this and rsync over the static files to get live refreshing for HTML/JS/CSS files
    export ASSETS_DIR=/home/<%=@run_as%>/cloudos-server/site/
    
    # Java server for API and frontend web listens on this port, comes from cloudos/ports.json databag
    export CLOUDOS_SERVER_PORT=<%=server_port%>
    
    # PostgreSQL password
    export CLOUDOS_DB_PASS=<%=@dbpass%>

    # Kerberos admin password
    # original source: generated on cloudos at setup-time
    export KADMIN_PASS=<%=@app[:passwords]['kerberos']%>

    # credentials for S3, where configs are stored using cloudos-lib library
    export AWS_ACCESS_KEY_ID=<%=@aws_access_key%>
    export AWS_SECRET_ACCESS_KEY=<%=@aws_secret_key%>
    
    # the bucket that all hosted cloudstead storage shares
    export S3_BUCKET=<%=@s3_bucket%>
    
    # the IAM user (determines the subfolder within the bucket that they have write permissions to)
    export AWS_IAM_USER=<%=@aws_iam_user%>
    
    # stored data is encrypted using this secret
    export CLOUD_STORAGE_DATA_KEY=<%=@data_key%>
    
    # sendgrid credentials
    # original source: generated on cloudstead server at launch time. new for every relaunch.
    export SENDGRID_USERNAME=<%=@sendgrid_username%>
    export SENDGRID_PASSWORD=<%=@sendgrid_password%>

    # the email templates live here
    export EMAIL_TEMPLATE_ROOT=/home/<%=@run_as%>/cloudos-server/email/

    # when the cloudos java server sends emails, it uses these creds
    # source: generated on cloudos at setup-time
    export SYSTEM_MAILER_USERNAME=<%=@app[:users]['cloudos_system_mailer'][:name]%>
    export SYSTEM_MAILER_PASSWORD=<%=@app[:users]['cloudos_system_mailer'][:password]%>

    # source: constant value 'cloudos_announce' set in chef recipe
    export ROOTY_QUEUE_NAME=<%=@app[:passwords]['rooty_queue']%>

    # source: generated on cloudos at setup-time
    export ROOTY_SECRET=<%=@app[:passwords]['rooty']%>

    # authy for 2-factor login
    # original source: .cloudstead.env file on cloudstead server. must be replaced before allowing ssh access.
    export AUTHY_KEY=<%=@app[:databag][:init]['cloudos']['authy']['user']%>
    export AUTHY_URI=<%=@app[:databag][:init]['cloudos']['authy']['base_uri']%>

    # for managing the DNS subdomain of this cloudstead
    export CLOUDOS_DNS_USER=<%=@app[:databag][:init]['cloudos']['dns']['user']%>
    export CLOUDOS_DNS_PASSWORD=<%=@app[:databag][:init]['cloudos']['dns']['password']%>
    export CLOUDOS_DNS_URI=<%=@app[:databag][:init]['cloudos']['dns']['base_uri']%>
    export CLOUDOS_DNS_ACCOUNT=<%=@app[:databag][:init]['cloudos']['dns']['account']%>
    export CLOUDOS_DNS_ZONE=<%=@app[:databag][:init]['cloudos']['dns']['zone']%>

----
## CloudOs Setup: Finalized and email setup link to admin user
### actor: cloudos-chef (on cloudos instance)
When chef has completed setting up the cloudos, it:
* generates a random secret and stores it in ~/.first\_time\_setup
* sends an email to the recovery\_email with a URL containing the secret key
* the end user follows the link and arrives at the CloudOs setup page (which validates that the secret key is correct)

----
## CloudOs Setup: Admin login, secure instance, and create accounts
### actor: end user (on cloudos instance)
The end user configures the CloudOs by:
* Entering their current account password (chef put it in ~/.first\_time\_setup in bcrypt'ed form) to validate they are the real user.
* Choose an account name and password for the cloudos admin account:
  * this will set their kerberos password, and log them in to the admin site, where they can add users (and later, add apps, monitor usage, etc)
  * this will also create their account in cloud storage (recovery_email will be same address as recovery_email, but can be changed)
  * their password on cloudstead.io public site will not change. we will no longer know their password for the box.
  * this will lastly truncate the ~/.first\_time\_setup file, which will ensure that on future "fresh" chef runs, the secret_key will not be regenerated and the setup email will not be sent.
* Setting up user accounts. Each user has a name, recovery\_email, and optional mobile\_phone. These are saved to the CloudOs's local database.
