FROM alpine:latest

ARG BUILD_DATE
#-- default environment variables
ENV VERBOSE=1
ENV URL_DNSPHPADMIN=https://github.com/benapetr/dnsphpadmin/releases/download/1.10.0/dnsphpadmin_1.10.0.tar.gz
ENV DIR_CODE=/var/dnsphpadmin
ENV DIR_CONF=/etc/dnsphpadmin

RUN apk --update --no-cache add apache2 apache2-ssl ssmtp bind-tools bind-libs \
  php-apache2 php-session php-openssl php-json php-xml php-gd php-ldap wget

#-- Redirect logs
RUN ln -sf /dev/stdout /var/log/apache2/access.log && ln -sf /dev/stderr /var/log/apache2/error.log

LABEL maintainer="Eugene Taylashev" \
  url="https://github.com/eugene-taylashev/docker-dnsphpadmin" \
  source="https://hub.docker.com/repository/docker/etaylashev/dnsphpadmin" \
  title="Run DnsPhpAdmin as a container" \
  description="DnsPhpAdmin is a DNS web admin panel written in PHP, designed to operate via nsupdate, for all kinds of RFC compliant DNS servers. "

#-- do preparations
RUN mkdir $DIR_CODE $DIR_CONF
RUN wget -qO- $URL_DNSPHPADMIN | tar -xvz --strip-components=1 -C $DIR_CODE

#-- ports exposed
EXPOSE 80
EXPOSE 443

#-- Volume with actual DnsPhpAdmin and configuration files
VOLUME $DIR_CONF

#-- default environment variables
ENV VERBOSE=0

COPY ./entrypoint.sh /usr/local/bin/

CMD ["entrypoint.sh"]
