FROM nginx:mainline-alpine
MAINTAINER Xan Manning <git@xan-manning.co.uk>

# Environment Variables
ENV php_conf /etc/php5/php.ini
ENV fpm_conf /etc/php5/php-fpm.conf
ENV DW_SSO ""
ENV DW_MAX_UPLOAD 256
ENV DW_GIT_PULL ""

# Install our requires software (related blocks)
RUN apk update
RUN apk add ca-certificates openssl
RUN apk add php5-fpm php5-gd php5-xml php5-ldap php5-mcrypt php5-pspell
RUN apk add git rsync bash
RUN apk add supervisor
RUN apk add zip unzip

# Update our CA certificates
RUN update-ca-certificates

# Make our farm directory
RUN mkdir -p /var/www/farm

# Make temporary directory for volumes
RUN mkdir -p /tmp/{conf,data,inc,farm}

# Add the configuration files
ADD run.sh /run.sh
ADD etc/nginx.conf /etc/nginx/nginx.conf
ADD etc/supervisord.conf /etc/supervisord.conf

# Configure our PHP
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
    sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = ${DW_MAX_UPLOAD}M/g" ${php_conf} && \
    sed -i "s/post_max_size\s*=\s*8M/post_max_size = ${DW_MAX_UPLOAD}M/g" ${php_conf} && \
    sed -i "s/;daemonize\s*=\s*yes/daemonize = no/g" ${fpm_conf} && \
    sed -i "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} && \
    sed -i "s/pm.max_children = 4/pm.max_children = 4/g" ${fpm_conf} && \
    sed -i "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} && \
    sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} && \
    sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} && \
    sed -i "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} && \
    sed -i "s/user = nobody/user = nginx/g" ${fpm_conf} && \
    sed -i "s/group = nobody/group = nginx/g" ${fpm_conf} && \
    sed -i "s/;listen.mode = 0660/listen.mode = 0666/g" ${fpm_conf} && \
    sed -i "s/;listen.owner = nobody/listen.owner = nginx/g" ${fpm_conf} && \
    sed -i "s/;listen.group = nobody/listen.group = nginx/g" ${fpm_conf} && \
    sed -i "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" ${fpm_conf}

# Clone DokuWiki from the repository
RUN git clone https://github.com/splitbrain/dokuwiki.git /var/www/dokuwiki

# Make sure we are on the stable release
RUN git --git-dir=/var/www/dokuwiki/.git --work-tree=/var/www/dokuwiki \
    checkout stable

# Configure our Farm
RUN wget https://www.dokuwiki.org/_media/dokuwiki_farm_animal.zip
RUN unzip dokuwiki_farm_animal.zip
RUN mv _animal /var/www/farm/_animal
RUN cp /var/www/dokuwiki/inc/preload.php.dist /var/www/dokuwiki/inc/preload.php
RUN sed -i "s/\/\/if(!defined('DOKU_FARMDIR'))/if(!defined('DOKU_FARMDIR'))/g" /var/www/dokuwiki/inc/preload.php && \
    sed -i "s/\/\/include(fullpath(dirname(__FILE__))/include(fullpath(dirname(__FILE__))/g" /var/www/dokuwiki/inc/preload.php

# Configure permissions
# Make Nginx the owner of all the files.
RUN chmod +x /run.sh
RUN chown -R nginx:nginx /var/www/farm
RUN chown -R nginx:nginx /var/www/dokuwiki

# Create backup of files for our volumes
RUN rsync -arvvlPHS /var/www/dokuwiki/conf/ /tmp/conf/ && \
    rsync -arvvlPHS /var/www/dokuwiki/data/ /tmp/data/ && \
    rsync -arvvlPHS /var/www/dokuwiki/inc/ /tmp/inc/ && \
    rsync -arvvlPHS /var/www/farm/ /tmp/farm/

# Serve traffic on port 80
EXPOSE 80

# Set out volumes
VOLUME [ "/var/www/farm/", "/var/www/dokuwiki/conf/", "/var/www/dokuwiki/data/", "/var/www/dokuwiki/inc/"]

# Entrypoint to the container being supervisord
ENTRYPOINT ["/run.sh"]
