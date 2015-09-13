Managing DNS on a Cloudstead
============================

Some apps require their own hostname. CloudOs is responsible for managing DNS for these apps.

However, CloudOs does not manage DNS directly. Instead, it connects to another DNS manager.

The two DNS managers supported by CloudOs are:

   * Dyn - connects your CloudOs to an account on Dyn.com to manage DNS
   * cloudos-dns - connects your CloudOs to a cloudos-dns server to manage DNS.
 
Depending on how it's configured, a cloudos-dns server will do one of the following:

   * connect to a Dyn account
   * manage a locally running djbdns server (also known as tinydns)
   * (on the roadmap) manage a locally running BIND server
 
Cloudsteads launched by cloudstead.io will be automatically configured to use a cloudos-dns server
running on cloudstead.io's servers, which in turn is connected to cloudstead.io's Dyn account.

Cloudsteads that you launch manually require configuration to connect them to an appropriate DNS manager.

## Connecting CloudOs to Dyn

### Before launching the cloudstead

To launch a new cloudstead that will use Dyn for DNS management:

   * When using the Cloudstead Launcher, fill out the "dyndns" section in the DNS tab.
   * When launching manually, edit the `data_bags/cloudos/init.json` file in your `init_files` directory. 
       * Remove `base_uri`, or set its value to be the empty string
       * Set `user` to your Dyn (regular user) username
       * Set `password` to that regular user's password 
       * Set `account` to the name of your DynDns account
       * Set `zone` to the zone that this cloudos instance will belong to.

### After launching the cloudstead

If you have an existing cloudstead that you'd like to use this DNS scheme with:

Via the CloudOs web interface:

   * Login to your CloudOs as a user with Admin privileges
   * In the top-right of the CloudOs taskbar, click Settings (the gears icon) and select "System Settings"
   * Select the "App Settings" tab
   * Select the "cloudos" app
       * Set `DNS base URI` to be the empty string
       * Set `DNS User` to your Dyn (regular user) username
       * Set `DNS Password` to that regular user's password 
       * Set `DNS Account` to the name of your DynDns account
       * Set `DNS Zone` to the zone that this cloudos instance will belong to

Via shell:

   * SSH into your cloudstead. Become root.
   * Edit the `cloudos/init.json` data bag. For example: `emacs $(bash -c "echo -n ~$(cat /etc/chef-user)")/chef/data_bags/cloudos/init.json`
   * Follow the instructions above to set the values in the `dns` section appropriately
   * Synchronize the chef repository with the CloudOs app repository: `cos sync-apps -e ~cloudos/.cloudos.env`
   * Restart the CloudOs server: `service cloudos restart`

## Connecting CloudOs to djbdns (aka tinydns)

First determine where the djbdns server will run. If you already have a djbdns server running somewhere else,
you can use that server by adding a cloudos-dns server to it. Alternatively, you can run djbdns and cloudos-dns
on the cloudstead itself.

### Using a pre-existing djbdns server

Your existing djbdns server will need to run a cloudos-dns server. This cloudos-dns server will be configured
to accept DNS management requests from your cloudstead, and handle those requests by configuring djbdns appropriately.

   * Install and configure the cloudos-dns server using the cloudos-dns standalone installer (todo: link to instructions)
   * Create a cloudos-dns account that the new cloudstead will use

Your cloudstead will use the cloudos-dns credentials you created above to connect to the cloudos-dns and manage DNS
records.

#### Before launching the cloudstead

To launch a new cloudstead that will use djbdns for DNS management:

   * When using the Cloudstead Launcher, fill out the "external DNS" section in the DNS tab.
   * When launching manually:
       * Edit the `data_bags/cloudos/init.json` file in your `init_files` directory. Edit the `dns` block (or add one if not present). 
          * Remove `base_uri`, or set its value to be the empty string
          * Set `user` to the cloudos-dns username you created
          * Set `password` to that user's password
          * Set `base_uri` to the base URL of your cloudos-dns server
       * Edit the `data_bags/base/base.json` file
          * Set `hostname` to the name of the cloudos-dns user you created
          * Set `parent_domain` to the DNS zone for the cloudos-dns user you created

#### After launching the cloudstead

If you have an existing cloudstead that you'd like to use this DNS scheme with:

Via the CloudOs web interface:

   * Login to your CloudOs as a user with Admin privileges
   * In the top-right of the CloudOs taskbar, click Settings (the gears icon) and select "System Settings"
   * Select the "App Settings" tab
   * Select the "cloudos" app
       * Set `DNS base URI` to be the base URL of your cloudos-dns server
       * Set `DNS User` to your cloudos-dns username
       * Set `DNS Password` to that user's password 

Via shell:

   * SSH into your cloudstead. Become root.
   * Edit the `cloudos/init.json` data bag. For example: `emacs $(bash -c "echo -n ~$(cat /etc/chef-user)")/chef/data_bags/cloudos/init.json`
   * Follow the instructions above to set the values in the `dns` section appropriately
   * Synchronize the chef repository with the CloudOs app repository: `cos sync-apps -e ~cloudos/.cloudos.env`
   * Restart the CloudOs server: `service cloudos restart`

### Using the built-in djbdns server

With this scheme, your Cloudstead will be its own primary DNS server and will run both djbdns and cloudos-dns.

#### Before launching the cloudstead

To launch a new cloudstead that will use djbdns for DNS management:

   * When using the Cloudstead Launcher, fill out the "builtin djbdns" section in the DNS tab.
       * Set the value of "Allow AXFR" to be a comma-separated list of IP addresses of secondary name servers

   * When launching manually, edit the `data_bags/djbdns/init.json` file in your `init_files` directory. 
       * Set `allow_axfr` to be a comma-separated list of IP addresses of secondary name servers

#### After launching the cloudstead

If you have an existing cloudstead and you'd like to use this DNS scheme with:

Via the CloudOs web interface:

   * Login to your CloudOs as a user with Admin privileges
   * In the top-right of the CloudOs taskbar, click Settings (the gears icon) and select "App Store"
       * Install the cloudos-dns and djbdns apps, or upgrade them to the latest version
   * In the top-right of the CloudOs taskbar, click Settings (the gears icon) and select "System Settings"
   * Select the "App Settings" tab
   * Select the "cloudos" app
       * Set `DNS base URI` to be the base URL of your cloudos-dns server
       * Set `DNS User` to your cloudos-dns username
       * Set `DNS Password` to that user's password 
   * Select the "djbdns" app
       * Set `allow_axfr` to be a comma-separated list of IP addresses of secondary name servers

Via shell:

   * SSH into your cloudstead. Become root.
   * Edit the `cloudos/init.json` data bag. For example: `emacs $(bash -c "echo -n ~$(cat /etc/chef-user)")/chef/data_bags/cloudos/init.json`
   * Follow the instructions above to set the values in the `dns` section appropriately
   * Edit the `djbdns/init.json` data bag. For example: `emacs $(bash -c "echo -n ~$(cat /etc/chef-user)")/chef/data_bags/djbdns/init.json`
   * Follow the instructions above to set the value of `allow_axfr`   
   * Synchronize the chef repository with the CloudOs app repository: `cos sync-apps -e ~cloudos/.cloudos.env`
   * Restart the CloudOs server: `service cloudos restart`
