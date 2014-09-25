# Third-Party Services

Cloudstead currently leverages a few third-party services to make setup easier. Many of these can be easily swapped out 
for your own services.

## Set up an AWS account

Cloudstead may use Amazon EC2 to launch new CloudOs instances. CloudOs instances use Amazon S3 to store their (encrypted) data, like backups.

If you do not want to use Amazon EC2, you can use Digital Ocean, which is also supported. If you prefer to use neither, you can launch 
your own cloudsteads directly onto systems that you fully control.
 
If you do not want to use Amazon S3, the backups can be written to a location on the local disk. Pluggable backup storage is on our roadmap.
 
## Set up a Digital Ocean account

Cloudstead may use Digital Ocean to launch new CloudOs instances. These CloudOs instances will still use Amazon S3 for their backup storage.
 
If you do not want to use Digital Ocean, you can use Amazon EC2, which is also supported. If you prefer to use neither, you can launch 
your own cloudsteads directly onto systems that you fully control.  

## Initialize AWS resources: S3 and IAM

This is a one-time step that only needs to be done once, ever. Normally, when launching a new CloudOs instance, the pubic site will
create an IAM user and generate an access key/secret key pair for that user, and these will be what the CloudOs instance runs with.

For dev purposes, you can use a "superuser" to make things easier, but you still need to create a separate IAM user.

* Log in to the AWS management console
* Create a new IAM user will full permissions
* Generate an access key/secret key for this user (and save them somewhere)
* Create an S3 bucket for testing

## Set up Authy account

CloudOs currently uses Authy for two-factor authentication. 
Create an account on Authy.com, and create an authy application. Note your Authy API key.

Authy is currently the only supported means of two-factor authentication. Pluggable two-factor auth services is on our roadmap.

## Set up Sendgrid account

CloudOs currently uses Sendgrid for outbound SMTP relaying.
Create an account on Sengdrid, and create a set of user credentials that has full permissions. Note these credentials.

If you do not want to use Sendgrid, then you'll need the credentials (username, password, host, and port) to another SMTP 
relay that supports TLS connections. You can adjust these settings after your CloudOs instance is running.

## Set up Dyn DNS account

CloudOs currently uses Dyn for dynamic DNS management.
Create an account on Dyn. Create a regular user account within your Dyn account. Note your API credentials for this account.
Create a DNS zone that Dyn will manage for you.

If you do not want to use Dyn, you can run your own cloudos-dns server that cloudos instances can use to manage their DNS.
The cloudos-dns server currently supports a backend of djbdns (aka tinydns). Adding support for Bind and other DNS servers is on our roadmap.
You can adjust these settings after your CloudOs instance is running.