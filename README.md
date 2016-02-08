# Docker image Magento2 with Magento Testing Framework (MTF)


Used for continuous integration/delivery of Magento2 components (modules,themes etc ...)
This image, based on official php repo, install magento2 and MTF sources with composer.

You can run your container in detached if you want.
But the goal, it's to run your custom test suite.

## Prerequisite

The Magento 2 GitHub repository requires you to authenticate.  
The composer install commands fails if you do not.  
To authenticate, generate authentication keys(http://devdocs.magento.com/guides/v2.0/install-gde/prereq/connect-auth.html#auth-get)), after which you assign this values in following environments variables:  
* `GITHUB_API_TOKEN`
* `MAGE_ACCOUNT_PUBLIC_KEY`
* `MAGE_ACCOUNT_PRIVATE_KEY`

When you run your container, add `--env` or `--env-file` argument to the run command.
Example with `--env-file`:
```
docker run -it --name magento2 -env-file auth.env -d -p 8080:80 sirateck/devops-magento2
```
Where content of auth.env file look like this:
```
GITHUB_API_TOKEN=870a63776fh84hdbef59dbaf17f9d065fab6d7
MAGE_ACCOUNT_PUBLIC_KEY=hge1b71430843e56jkce06baa27eb5f
MAGE_ACCOUNT_PRIVATE_KEY=hg67nbf8d359151f4193dkjd0412c4c3a9
```

## Environments variables

You can customize magento installation with environments variables.
See in [Dockerfile](Dockerfile) at the end for variables list.

## MTF

TODO

### TODO
Get custom component with composer

### TODO
Add use cases.

## Licence

The MIT License (MIT)

Copyright (c) 2016 Sirateck
