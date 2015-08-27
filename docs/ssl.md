SSL Certificates
================

An SSL certificate allows your Cloudstead to communicate securely.

You get your SSL certificate from a Certificate Authority, or CA for short. Popular CAs include Verisign and GoDaddy.

The process to get an SSL certificate for your cloudstead goes something like this:

 * Select a Certificate Authority (CA) to work with
 * Create a Private Key and a Certificate Signing Request (CSR) for a wildcard host name (e.g., *.cloud.example.com)
 * Use the CSR to request a certificate from the CA
 * The CA will verify your identity and your ownership of the domain name on the certificate
 * The CA issues your certificate

Your new SSL certificate has two parts - a public part and a private part. When starting a new cloudstead,
you'll need both of these files.

### A simple walkthrough  

I wanted to launch a cloudstead on a domain I own, let's call it example.com.  
This domain is registered with GoDaddy and uses their private DomainsByProxy service to keep my personal information
out of the WHOIS database.

StartSSL issues free SSL certificates and is a great place to get started. I signed up for an account with them, and 
then used their "Validations Wizard" to verify my identity and my ownership of example.com.

With these validations in place, I can now use their "Certificates Wizard" to request a certificate.

#### Generate a Private Key and CSR

    $ openssl genrsa -out ~/cloudstead/keys/example.com.key 2048
    
    $ openssl req -new -sha256 -key ~/cloudstead/keys/example.com.key -out ~/cloudstead/keys/example.com.csr
    
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:California
    Locality Name (eg, city) []:
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:Cloudstead, Inc.
    Organizational Unit Name (eg, section) []:
    Common Name (e.g. server FQDN or YOUR name) []:*.cloud.example.com
    Email Address []:
    
    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:

The most important field above is the "Common Name" field. When accessing your Cloudstead, this is the domain 