FROM debian:testing

EXPOSE 80/tcp
EXPOSE 3306/tcp

VOLUME /var/www \
       /var/lib/mysql

ENV document_root="" \
    host_uid="1000" \
    host_gid="1000" \
    xdebug_remote_host="172.17.0.1" \
    PHP_IDE_CONFIG="serverName=server" \
    xdebug_port="9000"

SHELL ["/bin/bash", "-c"]

COPY files /files

RUN cp /files/mysql_user_script.sh / && \
##############################
#       APT REPOSITORY       #
##############################
    cp /files/etc/apt/sources.list /etc/apt/sources.list && \
##############################
#          TIMEZONE          #
##############################
    unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
##############################
#           TOOLS            #
##############################
    apt-get -y update && \
    apt-get -y install gnupg && \
    apt-get -y install wget && \
##############################
#      MYSQL REPOSITORY      #
##############################
    apt-key add /files/mysql_pubkey.asc && \
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
    wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - && \
    echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list && \
    apt-get -y update && \
    #
    apt-get -y install php7.1 && \
    apt-get -y install libapache2-mod-php7.1 && \
    apt-get -y install php7.1-mbstring && \
    apt-get -y install php7.1-gd && \
    apt-get -y install php7.1-mysql && \
    #<xdebug>
    apt-get -y install php7.1-xml && \
    apt-get -y install php7.1-dev && \
    apt-get -y install php-pear && \
    pecl channel-update pecl.php.net && \
    pecl install xdebug && \
    apt-get -y remove php-pear && \
    apt-get -y remove php7.1-dev && \
    #</xdebug>
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
    sed -i "s|{{xdebug_port}}|$xdebug_port|" /etc/php/7.1/apache2/conf.d/20-xdebug.ini && \
    sed -i "s|{{xdebug_remote_host}}|$xdebug_remote_host|" /etc/php/7.1/apache2/conf.d/20-xdebug.ini && \
    sed -i "s|{{xdebug_port}}|$xdebug_port|" /etc/php/7.1/cli/conf.d/20-xdebug.ini && \
    sed -i "s|{{xdebug_remote_host}}|$xdebug_remote_host|" /etc/php/7.1/cli/conf.d/20-xdebug.ini && \
    service apache2 start && \
    service mysql start && \
    /bin/bash /mysql_user_script.sh && \
    su container_user && \
    /bin/bash
