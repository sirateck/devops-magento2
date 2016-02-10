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
		&& curl -sS https://getcomposer.org/installer | php -- --filename=composer -- --install-dir=/usr/local/bin \
		&& rm -r /var/lib/apt/lists/*

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
RUN adduser --disabled-password --gecos "" magento2 \
  && usermod -a -G www-data magento2 \
  && usermod -a -G magento2 www-data

WORKDIR /var/www/html/magento2

# Magento Version
ENV MAGE_VERSION=2.0.2 MAGE_SAMPLE_DATA_VERSION=2.0.2

# Get Magento CE release and sample data
RUN curl -o magento2-CE-$MAGE_VERSION.tar.gz -sSOL https://github.com/magento/magento2/archive/$MAGE_VERSION.tar.gz \
 && tar -xzf magento2-CE-$MAGE_VERSION.tar.gz

RUN curl -o magento2-sample-data-$MAGE_SAMPLE_DATA_VERSION.tar.gz -sSOL https://github.com/magento/magento2-sample-data/archive/$MAGE_SAMPLE_DATA_VERSION.tar.gz \
  && tar -xzf magento2-sample-data-$MAGE_SAMPLE_DATA_VERSION.tar.gz

RUN cp -rf magento2-$MAGE_VERSION/* . \
  && cp magento2-$MAGE_VERSION/.htaccess . \
  && cp -rf magento2-sample-data-$MAGE_SAMPLE_DATA_VERSION/* .

RUN rm -rf magento2-CE-$MAGE_VERSION.tar.gz magento2-sample-data-$MAGE_SAMPLE_DATA_VERSION.tar.gz magento2-$MAGE_VERSION/ magento2-sample-data-$MAGE_SAMPLE_DATA_VERSION/

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

#=================================================
# ENV credentials for repo.magento.com and github
#================================================
ENV GITHUB_API_TOKEN="" \
  MAGE_ACCOUNT_PUBLIC_KEY="" \
  MAGE_ACCOUNT_PRIVATE_KEY=""
COPY conf/auth.json.tmpl /tmp/

#====================================================
# If you want to use sample data with installation or reinstallaiton,
# set command argument value else let it empty
# Eg. ENV MAGE_INSTALL_SAMPLE_DATA --use-sample-data
#=====================================================
# Force complete reinstallaiton
ENV MAGE_REINSTALL=0 \
  MAGE_INSTALL_SAMPLE_DATA="--use-sample-data" \
  MAGE_ADMIN_FIRSTNAME="John" \
  MAGE_ADMIN_LASTNAME="Doe" \
  MAGE_ADMIN_EMAIL="john.doe@yopmail.com" \
  MAGE_ADMIN_USER="admin" \
  MAGE_ADMIN_PWD="admin123" \
  MAGE_BASE_URL="http://127.0.0.1:8080/magento2" \
  MAGE_BASE_URL_SECURE="https://127.0.0.1:8080/magento2" \
  MAGE_BACKEND_FRONTNAME="admin" \
  MAGE_DB_HOST="db" \
  MAGE_DB_PORT="3306" \
  MAGE_DB_NAME="magento2" \
  MAGE_DB_USER="magento2" \
  MAGE_DB_PASSWORD="magento2" \
  MAGE_DB_PREFIX="mage_" \
  MAGE_LANGUAGE="en_US" \
  MAGE_CURRENCY="USD" \
  MAGE_TIMEZONE="America/Chicago" \
  MAGE_USE_REWRITES=1 \
  MAGE_USE_SECURE=0 \
  MAGE_USE_SECURE_ADMIN=0 \
  MAGE_ADMIN_USE_SECURITY_KEY=0 \
  MAGE_SESSION_SAVE=files \
  MAGE_KEY="69c60a47f9dca004e47bf8783f4b9408"
#====================================================
# If you want to clean database with reinstallation,
# set command argument value else let it empty
# Eg. ENV MAGE_CLEANUP_DATABASE --cleanup-database
#=====================================================
ENV MAGE_CLEANUP_DATABASE="" \
  MAGE_DB_INIT_STATEMENTS="SET NAMES utf8;" \
  MAGE_SALES_ORDER_INCREMENT_PREFIX=0

#=================================================
# Env var used after installation
#=================================================
ENV MAGE_RUN_REINDEX=1 \
  MAGE_RUN_CACHE_CLEAN=0 \
  MAGE_RUN_CACHE_FLUSH=0 \
  MAGE_RUN_CACHE_DISABLE=1 \
  MAGE_RUN_STATIC_CONTENT_DEPLOY=1 \
	MAGE_RUN_SETUP_DI_COMPILE=0 \
  MAGE_RUN_DEPLOY_MODE=developer \
	MAGE_ENABLE_MODULE_MAGENTO_DEVELOPER=1

#============================================
# Env var used for custom package composer installation
# Env CUSTOM_MODULE is used for enable your module after required by composer
#============================================
ENV CUSTOM_REPOSITORIES=() \
  CUSTOM_PACKAGES=() \
  CUSTOM_MODULES=()

# Set developer mode in htaccess
RUN sed -i -e"s/#   SetEnv MAGE_MODE developer/   SetEnv MAGE_MODE developer/g" .htaccess

#=======================
# Prepare Dockerize template for MTF config
#=======================
COPY conf/auth.json.tmpl conf/mtf/phpunit.xml.tmpl conf/mtf/credentials.xml.tmpl conf/mtf/etc/config.xml.tmpl /tmp/


#==========================
# Selenium config (default host: selenium)
# Used by Magento testing framework
# You must to run your selenium server
# the best way is to use selenium image with docker-compose
#=========================
ENV SELENIUM_HOST selenium \
  SELENIUM_PORT 4444

COPY bin/magento2-start /usr/local/bin/
ENTRYPOINT ["magento2-start"]
