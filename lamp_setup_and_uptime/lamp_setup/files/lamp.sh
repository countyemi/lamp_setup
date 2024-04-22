#!/bin/sh

sudo apt update 

#set virtual host domain name
vHost=count

#set MySQL credentials
dbName=countdb
dbUser=countUser
dbPassword=countPasswd

#set repository url
gitRepo="https://github.com/laravel/laravel.git"

#install apache and git
sudo apt install apache2 git -y

echo ----------------------
echo apache2 and git installed

#set configuration file path
config_file="/etc/apache2/sites-available/$vHost.conf"

#install and start MySQL
sudo apt install mysql-server -y
sudo systemctl start mysql

echo ----------------------
echo MySQL-server installed

#create database, database user with password and grant database privilege to user
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $dbName;"
sudo mysql -e "CREATE USER '$dbUser'@'localhost' IDENTIFIED BY '$dbPassword';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $dbName.* TO '$dbUser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo ----------------------
echo database use $dbUser created with privilege to $dbName


#add php repository
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

#install php and other dependencies
sudo apt install php8.2 php8.2-mysql php8.2-intl php8.2-curl php8.2-mbstring php8.2-xml php8.2-zip  php8.2-ldap php8.2-gd php8.2-bz2 php8.2-sqlite3 php8.2-redis php8.2-cli php8.2-fpm unzip  libapache2-mod-php8.2 -y

#enable mod_rewrite
sudo a2enmod rewrite

echo ----------------------
echo php8.2 installed with dependencies

#Create Virtual Host on Apache
#sudo mkdir /var/www/$vHost

#copy configuration file to destination
sudo cp file.conf "$config_file"

#replace $vHost in configuration file with value
sudo sed -i "s/\$vHost/$vHost/g" "$config_file"


#enable virtual host
sudo a2ensite $vHost.conf
sudo systemctl restart apache2

#Download and install composer
curl -sS https://getcomposer.org/installer | php -q
sudo mv composer.phar /usr/local/bin/composer

echo ----------------------
echo composer installed

#clone git repo
git clone $gitRepo /var/www/$vHost

#change git repo directory owner to current user
sudo chown -R $USER:$USER /var/www/$vHost


#build application with composer
cd /var/www/$vHost
composer install --no-interaction
composer update --no-interaction
#copy environment variables
cp .env.example .env

#set path to .env file
env_file="/var/www/$vHost/.env"

#set database credentials
#change connection from sqlite to mysql
sed -i 's/DB_CONNECTION=sqlite/DB_CONNECTION=mysql/g' "$env_file"

#uncomment the MySQL configuration lines and update credentials
sed -i 's/# DB_HOST=127.0.0.1/DB_HOST=127.0.0.1/g' "$env_file"
sed -i 's/# DB_PORT=3306/DB_PORT=3306/g' "$env_file"
sed -i "s/# DB_DATABASE=laravel/DB_DATABASE=$dbName/g" "$env_file"
sed -i "s/# DB_USERNAME=root/DB_USERNAME=$dbUser/g" "$env_file"
sed -i "s/# DB_PASSWORD=/DB_PASSWORD=$dbPassword/g" "$env_file"


#generate application key
php artisan key:generate


#migrate database 
php artisan migrate

#populate database with initial data
php artisan db:seed

#set permissions for the laravel directory
sudo chown -R www-data storage
sudo chown -R www-data bootstrap/cache


