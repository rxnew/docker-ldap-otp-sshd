# docker-openssh-server
OpenSSH server on Docker

Supports the following authentication methods:
- LDAP
- Google Authenticator

## Environments
- `LDAP_URI` : URI of OpenLDAP server (e.g. `ldap://example.com`)
- `LDAP_BASEDN` : Base DN of LDAP (e.g. `dc=example,dc=com`)
- `LDAP_BINDDN` : Bind DN for sshPublicKey access of LDAP (e.g. `cn=admin,dc=example,dc=com`)
- `LDAP_BINDPW` : Bind password for sshPublicKey access of LDAP

## Volumes
- `/home` : User home directories
- `/var/lib/certs` : OpenSSH server certification files
- `/var/log/ssh` : OpenSSH server log files
