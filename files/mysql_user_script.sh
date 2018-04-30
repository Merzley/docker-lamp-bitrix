var=`mysql -p12345 <<< "SELECT host, user FROM mysql.user WHERE user='root'" | grep '%' | wc -l`;

if [[ $var != 1 ]]; then
  mysql -p12345 <<< "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '12345'";
  mysql -p12345 <<< "CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '12345'";
  mysql -p12345 <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION";
fi
