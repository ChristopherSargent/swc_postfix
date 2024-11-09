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
EXPOSE 25 465 587

# Start Postfix and Dovecot services
CMD ["sh", "-c", "service postfix start && service dovecot start && tail -f /var/log/mail.log"]

