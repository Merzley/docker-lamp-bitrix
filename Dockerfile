FROM debian:testing-slim

EXPOSE 80/tcp
EXPOSE 3306/tcp

VOLUME /var/www \
       /var/lib/mysql

ENV document_root="" \
    host_uid="" \
    host_gid=""

SHELL ["/bin/bash", "-c"]

COPY files /files

RUN cp /files/mysql_user_script.sh / && \
##############################
#          TIMEZONE          #
##############################
    unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
##############################
#      MYSQL REPOSITORY      #
##############################
    apt-get -y update && \
    apt-get -y install gnupg && \
    apt-key add /files/mysql_pubkey.asc && \
    apt-get -y remove gnupg && \
    cp -r /files/etc/apt/* /etc/apt && \
##############################
#        SYSTEM UPDATE       #
##############################
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install nano && \
##############################
#            MYSQL           #
##############################
    debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password 12345" && \
    debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password 12345" && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server && \
    service mysql stop && \
    rm -rf /var/lib/mysql/* && \
    cp -r /files/etc/mysql/* /etc/mysql && \
    chmod 0644 /etc/mysql/mysql.conf.d/mysqld.cnf && \
##############################
#            APACHE          #
##############################
    apt-get -y install apache2 && \
    a2enmod rewrite && \
    rm -rf /var/www/* && \
    rm /etc/apache2/sites-enabled/* && \
    rm /etc/apache2/sites-available/* && \
    cp -r /files/etc/apache2/* /etc/apache2 && \
##############################
#            PHP             #
##############################
    apt-get -y install php7.0 && \
    apt-get -y install libapache2-mod-php7.0 && \
    apt-get -y install php7.0-mbstring && \
    apt-get -y install php7.0-gd && \
    apt-get -y install php7.0-mysql && \
    apt-get -y install php7.0-xdebug && \
    cp -r /files/etc/php/* /etc/php && \
##############################
#            CLEAN           #
##############################
    rm -rf /files && \
    apt-get -y autoremove && \
    apt-get -y clean

CMD groupadd -g $host_gid container_group && \
    useradd -u $host_uid --shell /bin/bash --home /home/container_user container_user && \
    mkdir /home/container_user && \
    chown container_user:container_group /home/container_user && \
    sed -i "s|{{document_root}}|$document_root|" /etc/apache2/apache2.conf && \
    service apache2 start && \
    service mysql start && \
    /bin/bash /mysql_user_script.sh && \
    su container_user && \
    /bin/bash
