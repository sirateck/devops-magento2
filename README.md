# Docker image Magento2 with Magento Testing Framework (MTF)

Used for continuous integration/delivery of Magento2 components (modules,themes etc ...)
This image, based on official php repo, install magento2 and MTF sources with composer.

You can run your container in detached if you want.
But the goal, it's to run your custom test suite.

**DO NOT USE THIS IMAGE IN PRODUCTION, USE IT JUST FOR DEVELOPMENT.**

## Prerequisites

### Database server
This image need a mysql server but do not provide it.
The best way is to use **DOCKER COMPOSE**.

### Selenium server

If you want to use Magento Testing Framework you need a selenium server and this image don't provide it.
As like database server, The best way is to use **DOCKER COMPOSE**.
But if you want to see the test suite in your browser you can enter its host and port in environment variables (see Magento Testing Framework part below).

### Magento credentials
The Magento 2 GitHub repository requires you to authenticate.  
The composer install commands fails if you do not.  
To authenticate, generate authentication keys(http://devdocs.magento.com/guides/v2.0/install-gde/prereq/connect-auth.html#auth-get)), after which you assign this values in following environments variables:  
* `GITHUB_API_TOKEN`
* `MAGE_ACCOUNT_PUBLIC_KEY`
* `MAGE_ACCOUNT_PRIVATE_KEY`

See Environments variables part below.


## Environments variables

You can customize magento installation with environments variables.


When you run your container, add `-e`, `--env` or `--env-file` argument to the run command.  
The best way with many variables is `--env-file`.

Example with `--env-file`:
```
docker run -it --name magento2 -env-file ./auth.env -env-file ./mage.env -d -p 8080:80 sirateck/devops-magento2
```
Where content of auth.env file look like this:
```
GITHUB_API_TOKEN=870a63776fh84hdbef59dbaf17f9d065fab6d7
MAGE_ACCOUNT_PUBLIC_KEY=hge1b71430843e56jkce06baa27eb5f
MAGE_ACCOUNT_PRIVATE_KEY=hg67nbf8d359151f4193dkjd0412c4c3a9
```

And content of mage.env like this:
```
MAGE_INSTALL_SAMPLE_DATA=--use-sample-data
MAGE_ADMIN_FIRSTNAME=John
MAGE_ADMIN_LASTNAME=Doe
MAGE_ADMIN_EMAIL=john.doe@yopmail.com
MAGE_ADMIN_USER=admin
MAGE_ADMIN_PWD=admin123
MAGE_BASE_URL=http://127.0.0.1:8080/magento2
MAGE_BASE_URL_SECURE=https://127.0.0.1:8080/magento2
MAGE_BACKEND_FRONTNAME=admin
MAGE_DB_HOST=db
MAGE_DB_PORT=3306
MAGE_DB_NAME=magento2
MAGE_DB_USER=magento2
MAGE_DB_PASSWORD=magento2
MAGE_DB_PREFIX=mage_
MAGE_LANGUAGE=en_US
MAGE_CURRENCY=USD
MAGE_TIMEZONE=America/Chicago
MAGE_USE_REWRITES=1
MAGE_USE_SECURE=0
MAGE_USE_SECURE_ADMIN=0
MAGE_ADMIN_USE_SECURITY_KEY=0
MAGE_SESSION_SAVE=files
MAGE_KEY=69c60a47f9dca004e47bf8783f4b9408

#====================================================
#If you want to clean database with reinstallation,
# set command argument value else leave it empty
# Eg. MAGE_CLEANUP_DATABASE --cleanup-database
#=====================================================
MAGE_CLEANUP_DATABASE=
MAGE_DB_INIT_STATEMENTS=SET NAMES utf8;
MAGE_SALES_ORDER_INCREMENT_PREFIX=0

#=================================================
# Env var used after installation
#=================================================
MAGE_RUN_REINDEX=0
MAGE_RUN_CACHE_CLEAN=0
MAGE_RUN_CACHE_FLUSH=0
MAGE_RUN_CACHE_DISABLE=1
MAGE_RUN_STATIC_CONTENT_DEPLOY=0
MAGE_RUN_SETUP_DI_COMPILE=0
MAGE_RUN_DEPLOY_MODE=developer
```

See in [Dockerfile](Dockerfile) at the end for variables list.

## Install custom packages during a run command

You can install custom packages like *magento2 modules* after a fresh install during a run command.  
To do that just enter your packages repositories, packages urls and modules names in environments variables: `CUSTOM_REPOSITORIES`,`CUSTOM_PACKAGES`,`CUSTOM_MODULES`.

Environments variables file example (*Eg. module.env*):
```
CUSTOM_REPOSITORIES=vcs git@github.com:magento/magento2-samples.git
CUSTOM_PACKAGES=magento/sample-module-webflow dev-master
CUSTOM_MODULES=Magento_SampleWebFlow
```

In `CUSTOM_REPOSITORIES` variable you must do enter **type** and **repository**.  
In `CUSTOM_PACKAGES`, it's possible to add version or branch name.  
See https://getcomposer.org/doc/05-repositories.md

Your modules are enabled automatically.

## Magento command line

magento binary path is in PATH environment variable.  
So, you can easily run a magento command.  
May be for an unit test like this example below:  
```
docker run -it --name magento2 -env-file ./auth.env -env-file ./mage.env --env-file module.env -p 8080:80 sirateck/devops-magento2 magento dev:tests:run integration
```

More informations: http://devdocs.magento.com/guides/v2.0/config-guide/cli/config-cli-subcommands-test.html

## Magento Testing Framework

*Before run a test suite with mtf, you need a selenium server.*  
See: http://devdocs.magento.com/guides/v2.0/mtf/mtf_introduction.html

phpunit is already installed and phpunit binary path is in PATH environment variable.

So, you can easily run a test with run command:
```
docker run -it --name magento2 -env-file ./auth.env -env-file ./mage.env --env-file module.env -p 8080:80 sirateck/devops-magento2 phpunit --filter MyTestCase
```
For more information about run test see http://devdocs.magento.com/guides/v2.0/mtf/mtf_quickstart/mtf_quickstart_runtest.html

MTF configuration is already filled by Magento installation variables.  
If you want to change selenium host and port, change this values:
```
SELENIUM_HOST=selenium
SELENIUM_PORT=4444
```
Note:  At this moment, WYSIWYG Editor is not Disabled Completely before run test.

## Compose

With compose you get your dev environment in few minutes.

Juste create a directory with your env files and this docker-compose.yml file:
```
magento2:
  image: sirateck/devops-magento2
  ports:
    - "8080:80"
  links:
    - db
    - selenium
  env_file:
  - ./auth.env
  - ./module.env
  - ./mage.env
db:
  image: mysql:5.6
  environment:
    - MYSQL_ROOT_PASSWORD=magento2
selenium:
  image: selenium/standalone-firefox

```

Run another container with this compose file:
```
docker-compose run --rm magento2 some command
```

See [Docker Compose](https://docs.docker.com/compose/) for more informations.

## Licence

The MIT License (MIT)

Copyright (c) 2016 Sirateck
