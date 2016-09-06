# Dokuwiki Farm Docker Container

A convenient Dokuwiki container that can run as a farm.

## To run image:

There are a number of modes to run the Dokuwiki container.

### Quick start, Single Wiki

Below will run as a single wiki and is a quick, throw-away Dokuwiki container.

```
docker run -d -p 80:80 --name my_wiki xanmanning/dokuwiki-farm
```

Install this by going to your browser and running the installer
[http://localhost/install.php](http://localhost/install.php)

### Mounting volumes, Single Wiki

If you want to mount your config, data and inc directories to your host
run the following:

```
docker run -d -p 80:80 --name my_wiki \
    -v $(pwd)/data:/var/www/dokuwiki/data \
    -v $(pwd)/conf:/var/www/dokuwiki/conf \
    -v $(pwd)/inc:/var/www/dokuwiki/inc \
    xanmanning/dokuwiki-farm
```

### Starting a Wiki Farm

A wiki farm requires you to mount the farm directory to your host:

```
docker run -d -p 80:80 --name my_wiki_farm \
    -v $(pwd)/data:/var/www/dokuwiki/data \
    -v $(pwd)/conf:/var/www/dokuwiki/conf \
    -v $(pwd)/inc:/var/www/dokuwiki/inc \
    -v $(pwd)/farm:/var/www/farm \
    xanmanning/dokuwiki-farm
```

## Environment Variables

### Single Sign On for Farms

Set `DW_SSO` to 1, eg.:

```
docker run -d -p 80:80 --name my_wiki_farm \
    -e DW_SSO=1
    -v $(pwd)/data:/var/www/dokuwiki/data \
    -v $(pwd)/conf:/var/www/dokuwiki/conf \
    -v $(pwd)/inc:/var/www/dokuwiki/inc \
    -v $(pwd)/farm:/var/www/farm \
    xanmanning/dokuwiki-farm
```

### Git Pull on Restart

When re-starting containers do a git pull of the `stable` branch.

```
docker run -d -p 80:80 --name my_wiki_farm \
    -e DW_GIT_PULL=1
    -v $(pwd)/data:/var/www/dokuwiki/data \
    -v $(pwd)/conf:/var/www/dokuwiki/conf \
    -v $(pwd)/inc:/var/www/dokuwiki/inc \
    -v $(pwd)/farm:/var/www/farm \
    xanmanning/dokuwiki-farm
```
