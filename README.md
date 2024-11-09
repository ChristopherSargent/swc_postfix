1. psawx
2. sudo -i
3. cd /root/test/
4. mkdir postfix-relay
5. cd /root/test/postfix-relay
6. vim Dockerfile-ecs_postfix_relay
```
# Use Ubuntu as the base image
FROM ubuntu:22.04

# Install necessary packages
RUN echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y postfix net-tools dovecot-core dovecot-imapd dovecot-pop3d openssl vim iputils-ping

# Copy Postfix configuration files
COPY main.cf /etc/postfix/main.cf
COPY master.cf /etc/postfix/master.cf
COPY dovecot.conf /etc/dovecot/dovecot.conf

# Copy SSL certificates
COPY ssl/postfix.pem /etc/ssl/certs/postfix.pem
COPY ssl/postfix.key /etc/ssl/private/postfix.key

# Set permissions for SSL certificates
RUN chmod 600 /etc/ssl/private/postfix.key

# Expose necessary ports
EXPOSE 465 587

# Start Postfix and Dovecot services
CMD ["sh", "-c", "service postfix start && service dovecot start && tail -f /dev/null"]
```
7. vim main.cf
```
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2

# Enable TLS for outgoing mail
smtp_tls_security_level = may
smtp_tls_note_starttls_offer = yes

# Enable TLS for incoming mail
smtpd_tls_cert_file = /etc/ssl/certs/postfix.pem
smtpd_tls_key_file = /etc/ssl/private/postfix.key
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes

# Enable SASL authentication
#smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
#smtpd_sasl_auth_enable = yes
#smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination

# Adjust smtpd_recipient_restrictions to remove SASL requirement
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination

# Optional: Use strong ciphers and protocols
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_mandatory_ciphers = medium
smtpd_tls_exclude_ciphers = aNULL, MD5
smtp_tls_loglevel = 1

# TLS parameters
#smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
#smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
#smtpd_tls_security_level=may

#smtp_tls_CApath=/etc/ssl/certs
#smtp_tls_security_level=may
#smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = ecs.mbx.001
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
#myorigin = /etc/mailname
mydestination = $myhostname, ecs.mbx.001, gov, localhost.localdomain, localhost
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 172.18.1.0/24 10.100.0.141 172.19.0.0/16 172.19.0.3/16
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all
```
8. vim dovecot.conf
```
# Example Dovecot configuration
protocols = imap pop3 lmtp
ssl_cert = </etc/ssl/certs/postfix.pem
ssl_key = </etc/ssl/private/postfix.key
```
9. mkdir ssl && cd ssl && openssl req -new -x509 -days 365 -nodes -out postfix.pem -keyout postfix.key
10. cd ..
11. docker build -f Dockerfile-ecs_postfix_relay -t ecs_postfix_relay:1108202401 .
12. docker network create --subnet=172.18.0.0/24 tools_postfix_network
13. echo "10.100.0.141 ecs.mbx.001" >> /etc/hosts
14. docker exec tools_awx_1 echo "10.100.0.141 ecs.mbx.001" >> /etc/hosts


# Copy certs to AWX01

# Update trusted cert on AWX01
1. psawx01
2. sudo -i 
3. cp /root/test/postfix-relay/ssl/postfix.pem /etc/pki/ca-trust/source/anchors/postfix.crt
4. update-ca-trust

5. docker cp /root/test/postfix-relay/ssl/postfix.pem tools_awx_1:/etc/pki/ca-trust/source/anchors/postfix.crt
```
Successfully copied 3.07kB to tools_awx_1:/etc/pki/ca-trust/source/anchors/postfix.crt
```
6. docker exec -it -u:0 tools_awx_1 update-ca-trust

add 10.100.0.141 ecs.mbx.001 tools_awx_1 


