# Secure File Storage System (SFSS)

## Background

This is a client/server secure file storage system where the user can perform the various operations to manage files that is stored remotely in a secure manner and also encrypted at rest.

Operations Supported
- Register
- Upload
- Download
- Delete
- List

## Design

### Programming Langauge and Platform
Both the client and server are designed for Linux platforms.

### Client Implementation
The client is a command-line interface tool built using Perl programming language.

### Server Implementation
Server side is a web application built using Perl programming language server via Apache2 web server.

### Authentication
User will authentication and authorised via GitHub OAuth. Both the client and server will check against the Github OAuth to ensure the client has registered and for every access, the access token is checked via Github API to ensure it is authorised.

### Logging and comments
Comments and logging are put in place for easy debugging. For logging Log4Perl, a cousin port from Log4J is used.

### Networking
Data in transit are protected using proper HTTPS(SSL/TLS) transport between the client and server. In the testing environment, domain name verification is deliberately disabled at the client end, but in proper deployment where the server will be served public CA signed X.509 certificates, domain name verification can be enabled easily.

### Configuration
Configuration files are used for logging configurations, crendetials etc, so that they will be kept out of the codebase and changed for actual deployments.

### Security
As each user can be uniquely identified after authentication against the Github OAuth API, each user will contribute using it's unique ID to a common secret passphrase to form the actual passphrase for symmetric key encryption via AES. Hence different users even when uploaded the exact file will not encrypt to the same encrypted payload.
For simplicity, the filenames stored on disk are base64 encoded, so it will totally eliminate path traversal vulnerability.
If need be, AWS Secret Manager can be used for credentials management for better security.

### Rate Limiting
Rate limiting can be achieved using Apache2 module `mod_qos` to control the concurrency and rate of requests. This functionality is not part of the code feature.

## Installation

### Github OAuth App
A GitHub Oauth app will be required for OAuth authentication of users allowed to use the SFSS application.
#### Configuration
1) After login to your own Github account, go to `https://github.com/settings/apps`.
2) Click on `OAuth App` on the left panel, and click on `New OAuth App` button on the right.
3) The application name will need to be `sfss`.
4) Check `Enable Device Flow`
5) Click on `Register application` button

Once the application is created, click into it
1) Copy the Client ID
2) Generate a new Client Secret and copy it too

Edit the following json file that is copied to `/opt/sfss/config/config`
Except the `APPNAME` property that need to be `sfss` as configured in the `Github OAuth App`, the rest should be coped from `Github OAuth App` developer console.
```
{
  "APPNAME": "sfss",
  "CLIENTID": "<PASTE YOUR CLIENT ID>",
  "CLIENTSECRET": "<PASTE YOUR CLIENT SECRET>",
  "SFSS_COMMON_SECRET": "<ENTER YOUR PREFERRED COMMON FILE ENCRYPTION PASSPHRASE>"
}
```

### Client & Server
#### Required Linux Packages
```
apt install libcrypt-cbc-perl libjson-xs-perl libcgi-pm-perl apache2 libapache2-mod-qos liblog-log4perl-perl
```

### Client
Client application is a Perl script, hence it can be deployed in any systems that support the perl interpreter.
#### Installation
Copy the `client/sfss.pl` file to linux system. As long as there is a `perl` interpreter and also the above perl modules installed, it can be run from any directory `./sfss.pl <commands>`

Configure the `sfss.pl` code as follows. At the top of the code will contain the following codes
```
my $SFSS_PREFIX                = 'https://<IP/HOSTNAME OF APACHE SERVER WEB>/sfss';
...
my $GITHUB_CLIENTID            = '<PASTE YOUR CLIENT ID>';
...
```
Make sure the contents in these 2 variables are properly set.

### Server
As the server application is integrated with Apache2 web server, the root deployment will be found at `/opt/sfss`.

#### Installation
Copy the entire `server/sfss` to `/opt/sfss`
then run the following commands
```
sudo mkdir -p /opt/sfss/data
sudo chown -R www-data:www-data /opt/sfss
sudo find /opt/sfss -type d -exec chmod 0700 {} \;
sudo find /opt/sfss -type f -exec chmod 0600 {} \;
sudo find /opt/sfss/web -type f -exec chmod 0700 {} \;
sudo mkdir -p /var/log/sfss
sudo chown www-data:www-data /var/log/sfss
sudo chmod 0700 /var/log/sfss
```
HTTPS site can be enabled using
```
a2ensite default-ssl.conf
a2enmod ssl
a2enmod qos
```

```
<IfModule mod_ssl.c>
	<VirtualHost _default_:443>
		ServerAdmin webmaster@localhost

		DocumentRoot /var/www/html

...
        # ADDED FOR SFSS
        # ====================================================
		ScriptAlias "/sfss/" "/opt/sfss/web/"
        <Directory "/opt/sfss/web/">
            AllowOverride None
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
            Require all granted
        </Directory>
        # ====================================================
	</VirtualHost>
</IfModule>
```
