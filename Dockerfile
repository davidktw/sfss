FROM ubuntu:24.04 as sfss-client
WORKDIR /opt

COPY client/* /opt/sfss-client/

RUN apt-get -y update && apt-get -y install libcrypt-cbc-perl libjson-xs-perl libcgi-pm-perl liblog-log4perl-perl libwww-perl iputils-ping curl vim telnet
RUN echo 'export PATH="$PATH:/opt/sfss-client"' > /etc/profile.d/02-sfss-client.sh
RUN --mount=type=secret,id=mysecrets \
  set -a; . /run/secrets/mysecrets; \
  sed -i "s/___GITHUB_CLIENTID___/$CLIENTID/; s/___SFSS_SERVER_HOSTNAME___/$SFSSSERVERHOSTNAME/" /opt/sfss-client/sfss.pl

CMD bash -l

FROM ubuntu:24.04 as sfss-server
WORKDIR /opt

COPY server/sfss /opt/sfss
COPY server/apache2conf/sfss.conf /etc/apache2/sites-available/

RUN apt-get -y update && apt-get -y install libcrypt-cbc-perl libjson-xs-perl libcgi-pm-perl liblog-log4perl-perl libwww-perl apache2 vim
RUN \
	a2enmod ssl; \
	a2enmod cgid; \
	a2ensite sfss.conf; \
	mkdir -p /opt/sfss/data; \
	mkdir -p /opt/sfss/data; \
	chown -R www-data:www-data /opt/sfss; \
	find /opt/sfss -type d -exec chmod 0700 {} \;; \
	find /opt/sfss -type f -exec chmod 0600 {} \;; \
	find /opt/sfss/web -type f -exec chmod 0700 {} \;; \
	mkdir -p /var/log/sfss; \
	chown www-data:www-data /var/log/sfss; \
	chmod 0700 /var/log/sfss;
RUN --mount=type=secret,id=mysecrets \
  set -a; . /run/secrets/mysecrets; \
  sed -i "s/___CLIENTID___/$CLIENTID/; s/___APPNAME___/$APPNAME/; s/___CLIENTSECRET___/$CLIENTSECRET/; s/___COMMONSECRET___/$COMMONSECRET/" /opt/sfss/config/config

EXPOSE 443
CMD apachectl -D FOREGROUND
#CMD bash -l
