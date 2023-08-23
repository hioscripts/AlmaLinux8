#!/bin/bash

echo -en "This script will install Apache , MySQL,  PHPMyAdmin and Php. Do you want to Continue ? \nType y for yes and n for no : "
read a

if [ "$a" = "y"  ]
then
echo "updating system...."

yum install epel-release -y 

yum update && yum upgrade -y

echo "Installing Apache web server...."

yum install httpd -y

systemctl enable httpd

service httpd start 

echo "Apache server installed successfully"

#Allowing the port on FirewallD

echo "Opening port 80 on local firewall...."

firewall-cmd --permanent --add-service=http

firewall-cmd --reload

echo "Port 80 is now opened on firewall"

sleep 4

elif [	"$a" = "n" ]
then
exit
fi

# Creating virtual hosts..

virt_hosts(){

cd /etc/httpd/conf.d

echo -ne "Enter the domain name : "
read domain_name

touch "${domain_name%????}".conf

cat << EOF >> "${domain_name%????}".conf
<VirtualHost *:80>
  ServerName $domain_name
  ServerAlias www.$domain_name
  DocumentRoot /var/www/html/
  ErrorLog /etc/httpd/logs/error_log
</VirtualHost>
EOF

echo "Virtual hosts created successfully".

sleep 3

echo "Changing permissions for /var/www/html/"

chown -R apache:apache /var/www/html/

chmod 755 /var/www/html/

echo "Permission applied successfully"

sleep 3

echo "Changing SElinux Permission..."

yum install policycoreutils-python-utils -y

chcon -R -t httpd_sys_content_t /var/www/html 

}

#MySQL server install 

mysql_install(){

echo "Installing MySQL...."

sleep 2

cd $HOME

echo "Downloading MySQL 8 Community repo..."

curl -vo mysql80-community.rpm  https://dev.mysql.com/get/mysql80-community-release-el8-7.noarch.rpm -L

yum install mysql80-community.rpm -y 

echo "Mysql repository is installed"

sleep 2

echo "Installing MySQL8 Community server"

yum install mysql-server -y

systemctl enable mysqld

systemctl start mysqld

echo "MySQL community server installed successfully". 

#grep 'temporary password' /var/log/mysql/mysqld.log > tempass.txt

#echo "MySQL root temp password saved in a file tempass.txt on the current directory" 

sleep 3
}

#PHPMyAdmin Install

php_myadmin(){
 
echo "Creating folder to install phpmyadmin in home directory..."

sleep 3

mkdir $HOME/phpMyAdmin

echo "Navigating to the phpmyadmin folder..."

cd $HOME/phpMyAdmin

yum install wget tar -y 

wget -O phpMyAdmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz

tar -xzvf phpMyAdmin.tar.gz --strip-components=1 && cd ..

echo "Moving phpmyadmin to /usr/share location..."

mv phpMyAdmin /usr/share/phpMyAdmin

echo "Assigning apache permission for phpmyadmin directory ...."

chown -R apache:apache /usr/share/phpMyAdmin

chmod -R 755 /usr/share/phpMyAdmin

echo "Creating phpMyAdmin conf file..."

cd /etc/httpd/conf.d/ 

touch phpMyAdmin.conf

cat << EOF >> phpMyAdmin.conf
Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8

   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       Require all granted
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     #Deny from All
     Allow from 127.0.0.1
     Allow from ::1
     Allow from all
   </IfModule>
</Directory>

<Directory /usr/share/phpMyAdmin/setup/>
   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       Require ip 127.0.0.1
       Require ip ::1
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>
EOF
echo "Phpmyadmin config file created successfully"

sleep 4

echo "Applying SELinux permission...."

chcon -R -t httpd_sys_content_t /usr/share/phpMyAdmin/

}

#PHP Install

phpinstall(){

echo "Installing PHP remi repository...."

sleep 3

cd $HOME

curl -vo remi-release.rpm https://rpms.remirepo.net/enterprise/remi-release-8.rpm -L

yum install remi-release.rpm -y

sleep 3

echo -e "Type the number between 1 and 5 to install the required PHP version : "

php_ver=("7.4" "8.0" "8.1" "8.2" "8.3")

select php_version in "${php_ver[@]}"; do

case $php_version in 

  "7.4")
	echo "Installing php7.4..."
	dnf module reset php -y
        dnf module install php:remi-7.4 -y
  	yum install php php-cli  php-mysqlnd -y
	exit
  ;;
  "8.0")
        echo "Installing php8.0..."
        dnf module reset php -y
        dnf module install php:remi-8.0 -y
        yum install php php-cli php-mysqlnd -y
        exit
  ;;
  "8.1")
        echo "Installing php8.1..."
        dnf module reset php -y
        dnf module install php:remi-8.1 -y
        yum install php php-cli php-mysqlnd -y
	exit
  ;;
  "8.2")
        echo "Installing php8.2..."
        dnf module reset php -y
        dnf module install php:remi-8.2 -y
        yum install php php-cli php-mysqlnd -y
	exit
  ;;
  "8.3")
        echo "Installing php8.3..."
        dnf module reset php -y
        dnf module install php:remi-8.3 -y
        yum install php php-cli -y
	exit
	break
  ;;
      *)
	echo "Invalid option..."	
  ;;	
esac
done

}

echo -en "Do you want to create virtual hosts for a domain name ? \nType y for yes or n for no : "
read b

if [ "$b" = "y" ]
then
virt_hosts
mysql_install
php_myadmin
phpinstall

elif [ "$b" = "n" ]
then
mysql_install
php_myadmin
phpinstall
fi

echo "Restarting Apache web server...."

systemctl restart httpd

echo "Successfully installed Apache, MySQL , PHP and PHPMyAdmin..."

