## Installed

+ debian
+ apache2
+ mysql 5.7
+ php 7.0
+ xdebug

## Run container
```bash 
docker run  \
-itd \
-p 80:80 `#apache port` \ 
-p 3306:3306 `#mysql port` \
-v /path/to/db/storage:/var/lib/mysql \
-v /path/to/project/root:/var/www \
--env document_root=/src `#Document root for apache. Relative to project root` \
--env host_uid=1000 \
--env host_gid=1000 \
merzley/lamp-bitrix
```

## Apache config

```apacheconfig
DefaultRuntimeDir ${APACHE_RUN_DIR}

PidFile ${APACHE_PID_FILE}

Timeout 300

KeepAlive On

MaxKeepAliveRequests 100

KeepAliveTimeout 5

User container_user
Group container_group

HostnameLookups Off

ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined

ServerName localhost
DocumentRoot /var/www{{document_root}}
    
<Directory /var/www>
    Options FollowSymLinks

    AllowOverride All

    Require all granted
</Directory>


<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>

AccessFileName .htaccess

<FilesMatch "^\.ht">
	Require all denied
</FilesMatch>

LogLevel warn
LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

Include ports.conf
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
IncludeOptional conf-enabled/*.conf
```

## MYSQL config

```
[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
log-error       = /var/log/mysql/error.log
bind-address    = 0.0.0.0
symbolic-links  = 0
sql_mode        = ''
innodb_flush_log_at_trx_commit = 2
```

## PHP config

```
short_open_tag = On
opcache.revalidate_freq = 0
mbstring.func_overload = 2
default_charset = UTF-8
mbstring.internal_encoding = UTF-8
date.timezone = Europe/Moscow
max_input_vars = 10000
```

## XDebug config

```
zend_extension = xdebug.so

;PROFILER
xdebug.profiler_enable = 0
xdebug.profiler_output_dir = /var/www/xdebug
xdebug.profiler_output_name = %t.%R.profiler

;DEBUGGER
xdebug.remote_autostart = on
xdebug.remote_enable = on
xdebug.remote_handler = dbgp
xdebug.remote_connect_back = on
xdebug.remote_port = 9000
xdebug.remote_mode = req
xdebug.idekey = XDEBUG_IDE_KEY
```
