FROM ubuntu:trusty
MAINTAINER Pablo Leonardo Mendes da Cruz Lima "pabloleomendes@gmail.com"

RUN apt-get update && apt-get install -y aptitude \
	vim \
	htop \
	lighttpd \
	screen \
	subversion \
	php5-dev \
	php5-cgi \
	php-pear \
	php5-json \
	php5-common \
	php5-curl \
	php5-gd \
	php5-xdebug \
	libaio1 \
	php-soap \
	php5-ldap \
	php5-mcrypt \
	php5-mysql \
	php5-pgsql \
	php5-readline \
	php5-sasl \
	make \
	gcc \
	re2c	

WORKDIR /etc/lighttpd/conf-enabled/
RUN ln -s ../conf-available/15-fastcgi-php.conf
RUN ln -s ../conf-available/10-fastcgi.conf

ADD ./modules/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf
RUN chmod 0644 /etc/lighttpd/lighttpd.conf

RUN mkdir -p /usr/lib/oracle
ADD ./modules/oracle/ /usr/lib/oracle/
RUN tar -zxvf /usr/lib/oracle/instant_client.tar.gz -C /usr/lib/oracle/ 
ENV ORACLE_HOME /usr/lib/oracle/instantclient_11_2/
RUN rm -Rf /usr/lib/oracle/instant_client.tar.gz
RUN chmod 777 -Rf /usr/lib/oracle/
RUN ln -s $ORACLE_HOME/libclntsh.so.11.1 $ORACLE_HOME/libclntsh.so
RUN ln -s $ORACLE_HOME/libocci.so.11.1 $ORACLE_HOME/libocci.so
##################RUN pecl install oci8-1.4.10
RUN mkdir -p /tmp/phpoci/oci8php
ADD ./modules/oci8php /tmp/phpoci/oci8php
WORKDIR /tmp/phpoci/oci8php
RUN phpize
RUN sh configure --with-oci8=instantclient,/usr/lib/oracle/instantclient_11_2
RUN make -si
RUN make install -is
RUN chmod 777 -Rf /usr/lib/oracle/
RUN touch /etc/php5/cgi/conf.d/oci8.ini
RUN echo 'extension=oci8.so' >> /etc/php5/cgi/conf.d/oci8.ini
RUN chmod 777 /etc/php5/cgi/conf.d/oci8.ini
RUN sed -i -- 's/short_open_tag = Off/short_open_tag = On/g' /etc/php5/cgi/php.ini
RUN chown -R www-data:www-data /var/log/lighttpd/

RUN mkdir /var/run/lighttpd
RUN chown -R www-data:www-data /var/run/lighttpd

EXPOSE 80

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
