# Building a new CloudOs instance

First, follow the instructions in the [previous section](developing.md) to build the cloudos-server.tar.gz package. This will be needed
when the deployer installs the cloudos app bundle.

Also ensure you have appropriate credentials for the various required [third party services or alternatives](thirdparty.md).

## Setup the init-files for the instance

* In `cloudos-server/chef-repo`, make a copy of the `init_files` directory:

    `cp -R init_files my_init_files`

* Edit the following files, which will become databags accessible during the chef run:

    * `my_init_files/data_bags/cloudos/base.json`
    * `my_init_files/data_bags/cloudos/init.json`
    * `my_init_files/data_bags/email/init.json`
    * If you will be using cloudos-dns instead of Dyn, you will also edit:
      * `my_init_files/data_bags/cloudos-dns/init.json` 
    
* For `cloudos/base.json`:
    * Set `hostname` to whatever you want the hostname of the cloudstead to be. Use a one-word hostname, without any dots.
    * Set `parent_domain` to cloudstead.io
* For `cloudos/init.json`:
      * Set `server_tarball` to the URL where the cloudos-server.tar.gz tarball lives (you [copied it there](basics.md), right?)
      * Set `admin_initial_pass` to the bcrypt'ed password of the initial admin user. If you're lazy you can use `$2a$08$6ceARPPGxrCVhk7aGb3Xkeon1sEjtGV4fLSvw1h3U8PJA6/3jqSvK` which is the hash of 'lkjlkj'
      * Set `recovery_email` to your email address. This is where setup instructions will be emailed once the chef run is complete
      * Set `aws_iam_user` to an IAM user that you manually created above
      * Set `aws_access_key` and `aws_secret_key` to the credentials for this IAM user
      * Set `s3_bucket` to the bucket that you created above
      * In the `authy` section set `user` to your Authy API key
      * In the `dns` section:
        * If you're using Dyn for DNS management:
          * Remove `base_uri`, or set its value to be the empty string
          * Set `user` to your Dyn (regular user) username
          * Set `password` to that regular user's password 
          * Set `account` to the name of your DynDns account
          * Set `zone` to the zone that this cloudos instance will belong to.
        * If you're using cloudos-dns:
          * Leave `user` as-is (or match to admin.name in `cloudos-dns/init.json`)
          * Set `password` to a password of your choosing 
          * Set `base_uri` to `https://localhost/dns/api`
          * Remove `account` and `zone`
          * Edit `cloudos-dns/init.json`:
            * Set `admin.password` to the bcrypted of the `password` above, run `bcrypt <password>`
            * Ensure `admin.name` matches `dns.user` defined in `cloudos/init.json`
      
* For `email/init.json`:
      * In the `smtp_relay` section set `username` and `password` to your SendGrid username and password.

* Copy the wildcard SSL certificate/key into the `my_init_files/certs` directory
  * `ssl-https.key` and `ssl-https.pem` are the wildcard certificates for \*.yourdomain.com, these get installed on your new CloudOs instance.
  * You can use self-signed cerificates if you're willing to put up with warnings and add exceptions, or you can get buy a real SSL wildcard certificate from any number of reputable vendors.

## Prepare a new VirtualBox instance

* In VirtualBox, clone your base instance and launch the clone.
* When the clone comes up, log in and run `ifconfig` to see what IP address it got.

## Build the CloudOs instance

* In cloudos-server/chef-repo, run:
`INIT_FILES=my_init_files SSH_KEY=/path/to/your/private_key ./deploy.sh ubuntu@ip-of-virtualbox`
* The SSH key must be one that has password-less SSH access for the ubuntu user (which in turn has password-less sudo, so it can run chef as root)
* Go get a coffee or a tea. When the chef run is complete, check your email (the `recovery_email` from above) for a link.
* Click the link (ensure your `/etc/hosts` is correct if you're not using a public IP address)
* Setup your admin account (use the `initial_admin_password`) and maybe create some regular accounts.
* Play around, your instance is now live!

## Caveats

* CloudOs uses Kerberos for SSO (single-signon), and Kerberos *really* wants the system clock to be accurate.
If the clock drifts too far, logins will take a really long time or not work at all. This can happen easily if you suspend your instance,
or if your local dev system goes to sleep while VirtualBox is running. If this happens, the remedy is:
`sudo ntpdate 0.debian.pool.ntp.org`

Since this command might be hard/impossible to run if you can't login (like when Kerberos is broken due to excessive clock skew),
I usually leave the original VirtualBox console window logged in as root.
