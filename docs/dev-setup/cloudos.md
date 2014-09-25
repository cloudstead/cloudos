# Building a new CloudOs instance

First, follow the instructions in the [previous section](basics.md) to build the cloudos-server.tar.gz package. This will be needed
when the chef run installs the cloudos app bundle.

Also ensure you have appropriate credentials for the various required [third party services or alternatives](thirdparty.md)

## Setup the init-files for the instance

* In `cloudos-server/chef-repo`, make a copy of the `init_files` directory:

    `cp -R init_files my_init_files`

* Edit the following files, which will become databags accessible during the chef run:

    * `my_init_files/data_bags/cloudos/init.json`
    * `my_init_files/data_bags/email/init.json`
    
* For `cloudos/init.json`:
    * In the `base` section:
      * Set `hostname` to whatever you want the hostname of the cloudstead to be. Use a one-word hostname, without any dots.
      * Set `parent_domain` to cloudstead.io
  * In the `cloudos` section:
      * Set `server_tarball` to the URL where the cloudos-server.tar.gz tarball lives (you [copied it there](basics.md), right?)
      * Set `admin_initial_pass` to the bcrypt'ed password of the initial admin user. If you're lazy you can use `$2a$08$6ceARPPGxrCVhk7aGb3Xkeon1sEjtGV4fLSvw1h3U8PJA6/3jqSvK` which is the hash of 'lkjlkj'
      * Set `recovery_email` to your email address. This is where setup instructions will be emailed once the chef run is complete
      * Set `aws_iam_user` to an IAM user that you manually created above
      * Set `aws_access_key`, `aws_secret_key` to the credentials for this IAM user
      * Set `s3_bucket` to the bucket that you created above
      * In the `authy` section set `user` to your Authy API key
      * In the `dns` section:
        * Set `user` to your Dyn (regular user) username
        * Set `password` to that regular user's password 
        * Set `account` to the name of your DynDns account
        * Set `zone` to the zone that this cloudos instance will belong to.
      
* For `email/init.json`:
      * In the `smtp_relay` section set `username` and `password` to your SendGrid username and password.

* Copy the wildcard SSL certificate/key into the `my_init_files/certs` directory
  * `ssl-https.key` and `ssl-https.pem` are the wildcard certificates for \*.yourdomain.com, these get installed on your new CloudOs instance

## Prepare a new VirtualBox instance

* In VirtualBox, clone your base instance and launch the clone.
* When the clone comes up, log in and run `ifconfig` to see what IP address it got.

## Build the CloudOs instance

* In cloudos-server/chef-repo, run:
`INIT_FILES=my_init_files SSH_KEY=/path/to/your/private_key ./deploy.sh ubuntu@ip-of-virtualbox`
* The SSH key must be one that has password-less SSH access for the ubuntu user (which in turn has password-less sudo, so it can run chef as root)
* Go get a coffee. When the chef run is complete, check your email (the `recovery_email` from above) for a link.
* Click the link (ensure your `/etc/hosts` is correct)
* Setup your admin account (use the `initial_admin_password`) and maybe create some regular accounts.
* Play around, your instance is now live!

## Caveats

* CloudOs uses Kerberos for SSO (single-signon), and Kerberos *really* wants the system clock to be accurate.
If the clock drifts too far, logins will take a really long time or not work at all. This can happen easily if you suspend your instance,
or if your local dev system goes to sleep while VirtualBox is running. If this happens, the remedy is:
`sudo ntpdate 0.debian.pool.ntp.org`

Since this might be hard/impossible if you can't login (when Kerberos is borked),
I usually leave the original VirtualBox console window logged in as root.
