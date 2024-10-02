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
