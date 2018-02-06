FROM centos:7

LABEL maintainer="rxnew <rxnew.axdseuan+a@gmail.com>"
LABEL version="1.0"

ENV LDAP_URI='ldap://ldapd' \
    LDAP_BASEDN='dc=example,dc=com' \
    LDAP_BINDDN='cn=admin,dc=example,dc=com' \
    LDAP_BINDPW='password'

WORKDIR /root

RUN yum -y install openssh-server pam-devel git authconfig sssd sssd-client sssd-ldap openldap-clients && \
    yum -y groupinstall "Development Tools" && \
    rm -rf /var/cache/yum/* && \
    yum clean all && \
    git clone https://github.com/google/google-authenticator-libpam.git && \
    cd /root/google-authenticator-libpam && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    make install && \
    make clean && \
    cd /root && \
    rm -rf /root/google-authenticator-libpam && \
    yum -y remove git && \
    yum -y groupremove "Development Tools"

COPY pam/ /etc/pam.d/
COPY bin/ .

RUN chmod 700 ldap-ssh-authorizedkeys docker-entrypoint.sh && \
    mv ldap-ssh-authorizedkeys /bin/ldap-ssh-authorizedkeys && \
    mv google-authenticator.sh /etc/profile.d/google-authenticator.sh && \
    mv docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    cp /usr/local/lib/security/pam_google_authenticator.so /usr/lib64/security/ && \
    sed -i -e 's/^\(auth *substack *\)password-auth$/\1google-auth/g' /etc/pam.d/sshd && \
    sed -i -e 's/^#\?\(AuthorizedKeysCommand\) .*$/\1 \/bin\/ldap-ssh-authorizedkeys/g' /etc/ssh/sshd_config && \
    sed -i -e 's/^#\?\(AuthorizedKeysCommandUser\) .*$/\1 root/g' /etc/ssh/sshd_config && \
    sed -i -e '/^ChallengeResponseAuthentication/s/no/yes/g' /etc/ssh/sshd_config && \
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config

RUN authconfig \
    --enablesssd \
    --enablesssdauth \
    --enablelocauthorize \
    --disableldap \
    --disableldapauth \
    --disableldaptls \
    --enablemkhomedir \
    --update

EXPOSE 22

VOLUME ["/home", "/var/lib/certs", "/var/log/ssh"]

ENTRYPOINT ["docker-entrypoint.sh"]
