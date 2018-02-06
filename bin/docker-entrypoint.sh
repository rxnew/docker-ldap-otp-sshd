#!/bin/bash

cat <<EOF > /etc/sssd/sssd.conf
[sssd]
debug_level         = 0
config_file_version = 2
services            = nss, pam, ssh, sudo
domains             = default

[domain/default]
id_provider     = ldap
auth_provider   = ldap
chpass_provider = ldap
sudo_provider   = ldap

ldap_uri              = $LDAP_URI
ldap_search_base      = $LDAP_BASEDN
ldap_id_use_start_tls = False

ldap_search_timeout              = 3
ldap_network_timeout             = 3
ldap_opt_timeout                 = 3
ldap_enumeration_search_timeout  = 60
ldap_enumeration_refresh_timeout = 300
ldap_connection_expire_timeout   = 600

ldap_sudo_smart_refresh_interval = 600
ldap_sudo_full_refresh_interval  = 10800

entry_cache_timeout = 1200
cache_credentials   = True

[nss]
homedir_substring = /home

entry_negative_timeout        = 20
entry_cache_nowait_percentage = 50

[pam]

[sudo]

[autofs]

[ssh]

[pac]

[ifp]
EOF

chmod 600 /etc/sssd/sssd.conf

cat <<EOF > /etc/ssh/ldap.secrets
LDAP_URI='$LDAP_URI'
LDAP_BASEDN='$LDAP_BASEDN'
LDAP_BINDDN='$LDAP_BINDDN'
LDAP_BINDPW='$LDAP_BINDPW'
EOF

chmod 600 /etc/ssh/ldap.secrets

ssh-keygen -A

files=$(cat <<EOF
moduli
ssh_host_dsa_key
ssh_host_dsa_key.pub
ssh_host_ecdsa_key
ssh_host_ecdsa_key.pub
ssh_host_ed25519_key
ssh_host_ed25519_key.pub
ssh_host_key
ssh_host_key.pub
ssh_host_rsa_key
ssh_host_rsa_key.pub
EOF
)

for file in $files
do
    if [ -e /var/lib/certs/$file ]
    then
        cp -p /var/lib/certs/$file /etc/ssh/
    elif [ -e /etc/ssh/$file ]
    then
        cp -p /etc/ssh/$file /var/lib/certs/
    fi
done

rm -f /var/run/sssd.pid /var/run/sshd.pid

/usr/sbin/sssd -D &
echo Starting up sssd

/usr/sbin/sshd -D -E /var/log/ssh/secure &
echo Starting up sshd

trap_cmd() {
    sssd_pid=$(ps --no-heading -C sssd -o pid | tr -d ' ')
    sshd_pid=$(ps --no-heading -C sshd -o pid | tr -d ' ')
    [ ! -z "$sssd_pid" ] && kill $sssd_pid && echo Shutting down sssd
    [ ! -z "$sshd_pid" ] && kill $sshd_pid && echo Shutting down sshd
    exit 0
}

trap 'trap_cmd' TERM

sleep 5

while :
do
    sssd_pid=$(ps --no-heading -C sssd -o pid | tr -d ' ')
    sshd_pid=$(ps --no-heading -C sshd -o pid | tr -d ' ')
    [ -z "$sssd_pid" -o -z "$sshd_pid" ] && echo Process is down && exit 1
    sleep 1
done
