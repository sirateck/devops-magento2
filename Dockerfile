FROM php:5.6-apache

MAINTAINER Kassim Belghait <kassim@sirateck.com>

#================================================
# Customize sources for apt-get
#================================================
RUN echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-5.6\n" > /etc/apt/sources.list.d/mysql.list
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5

#======================
# Install packages needed by php's extensions
# PHP image already install following extensions:
#	- openssl, curl, zlib,recode,realine,mysqlnd
#======================
RUN apt-get update \
	&& apt-get -qqy --no-install-recommends install \
		git \
	 	libmcrypt-dev \
		libjpeg62-turbo-dev \
		libpng12-dev \
		libfreetype6-dev \
		libxslt1-dev \
		libicu-dev \
		mysql-client \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure zip --enable-zip \
    && docker-php-ext-install mcrypt gd intl mbstring soap xsl zip pdo_mysql \
		&& curl -sS https://getcomposer.org/installer | php -- --filename=composer -- --install-dir=/usr/local/bin

#Install gosu To run script as magento2 user
RUN curl -o /usr/local/bin/gosu -fsSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
	  && chmod +x /usr/local/bin/gosu

#===============
# PHP configuration
#===============
ENV PHP_TIMEZONE Europe/Paris
COPY conf/php.ini /usr/local/etc/php/
RUN echo "date.timezone = '$PHP_TIMEZONE'" >> /usr/local/etc/php/php.ini \
	&& ln -s /usr/local/bin/php /usr/bin/php

#====================================
# Apache configuration
# Active mod rewrite
#====================================
RUN a2enmod rewrite

#=============================
# Create Magento2 user and put it in web server's group
#============================
RUN adduser --disabled-password --gecos "" magento2
RUN usermod -a -G www-data magento2
RUN usermod -a -G magento2 www-data

WORKDIR /var/www/html/magento2

#===========================
# Copy composer config
# Copy auth.json (required by repo.magento.com) in HOME directories
# Copy composer.json
#===========================
COPY conf/auth.json /home/magento2/.composer/
COPY conf/auth.json /root/.composer/
RUN chown -R magento2:magento2 /home/magento2/ && chmod -R 770 /home/magento2/
COPY conf/composer.json.dist composer.json

# Get Magento CE metapackage and sample data
RUN composer install

# Get dockerize (used for waiting services)
RUN curl -o dockerize-linux-amd64-v0.2.0.tar.gz -sSOL https://github.com/jwilder/dockerize/releases/download/v0.2.0/dockerize-linux-amd64-v0.2.0.tar.gz
RUN tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.2.0.tar.gz
RUN chmod u+x /usr/local/bin/dockerize

#=========================
# Download MFT
#=========================
WORKDIR dev/tests/functional/
RUN composer install
ENV PATH=/var/www/html/magento2/dev/tests/functional/vendor/bin:$PATH
WORKDIR /var/www/html/magento2

#=============================
# Set file system ownership and permissions
#============================
RUN chown -R magento2:www-data .
RUN find . -type d -exec chmod 770 {} \; \
	&& find . -type f -exec chmod 660 {} \; \
	&& chmod u+x bin/magento \
	&& chmod u+x /var/www/html/magento2/dev/tests/functional/vendor/phpunit/phpunit/phpunit



# magento binary to global path
ENV PATH=/var/www/html/magento2/bin:$PATH
RUN echo 'PATH=/var/www/html/magento2/bin:$PATH' >> /home/magento2/.profile
#==========================
# ENV variables used by magento installation
#==========================
ENV MYSQL_ROOT_PASSWORD magento2

# Force complete reinstallaiton
ENV MAGE_REINSTALL  0

#====================================================
# If you want to use with installation or reinstallaiton,
# set command argument value else let it empty
# Eg. ENV MAGE_INSTALL_SAMPLE_DATA --use-sample-data
#=====================================================
ENV MAGE_INSTALL_SAMPLE_DATA --use-sample-data

ENV MAGE_ADMIN_FIRSTNAME John
ENV MAGE_ADMIN_LASTNAME Doe
ENV MAGE_ADMIN_EMAIL john.doe@yopmail.com
ENV MAGE_ADMIN_USER admin
ENV MAGE_ADMIN_PWD admin123
ENV MAGE_BASE_URL http://127.0.0.1:8080/magento2
ENV MAGE_BASE_URL_SECURE https://127.0.0.1.101:8080/magento2
ENV MAGE_BACKEND_FRONTNAME admin
ENV MAGE_DB_HOST db
ENV MAGE_DB_PORT 3306
ENV MAGE_DB_NAME magento2
ENV MAGE_DB_USER magento2
ENV MAGE_DB_PASSWORD magento2
ENV MAGE_DB_PREFIX mage_
ENV MAGE_LANGUAGE fr_FR
ENV MAGE_CURRENCY EUR
ENV MAGE_TIMEZONE Europe/Paris
ENV MAGE_USE_REWRITES 1
ENV MAGE_USE_SECURE 0
ENV MAGE_USE_SECURE_ADMIN 0
ENV MAGE_ADMIN_USE_SECURITY_KEY 0
ENV MAGE_SESSION_SAVE files
ENV MAGE_KEY 69c60a47f9dca004e47bf8783f4b9408

#====================================================
# If you want to clean database with reinstallation,
# set command argument value else let it empty
# Eg. ENV MAGE_CLEANUP_DATABASE --cleanup-database
#=====================================================
ENV MAGE_CLEANUP_DATABASE ''

ENV MAGE_DB_INIT_STATEMENTS  SET NAMES utf8;
ENV MAGE_SALES_ORDER_INCREMENT_PREFIX 0

# Set developer mode in htaccess
RUN sed -i -e"s/#   SetEnv MAGE_MODE developer/   SetEnv MAGE_MODE developer/g" .htaccess

#=======================
# Dockerize MFT config
#=======================
COPY conf/mtf/phpunit.xml.tmpl /tmp/
COPY conf/mtf/credentials.xml.tmpl /tmp/
COPY conf/mft/etc/config.xml.tmpl /tmp/etc/

#==========================
# Selenium config (default host: selenium)
# Used by Magento testing framework
# You must to run your selenium server
# the best way is to use selenium image with docker-compose
#=========================
ENV SELENIUM_HOST selenium
ENV SELENIUM_PORT 4444

COPY bin/magento2-start /usr/local/bin/
ENTRYPOINT ["magento2-start"]
