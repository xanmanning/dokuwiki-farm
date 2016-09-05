FROM nginx:mainline-alpine
MAINTAINER Xan Manning <git@xan-manning.co.uk>

ENV php_conf /etc/php5/php.ini
ENV fpm_conf /etc/php5/php-fpm.conf

RUN apk update
RUN apk add php5-fpm php5-imagick
RUN apk add git
RUN apk add supervisor

RUN mkdir -p /var/www/farm

ADD run.sh /run.sh
ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/supervisord.conf /etc/supervisord.conf

RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
    sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 256M/g" ${php_conf} && \
    sed -i "s/post_max_size\s*=\s*8M/post_max_size = 256M/g" ${php_conf} && \
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

RUN git clone https://github.com/splitbrain/dokuwiki.git /var/www/dokuwiki
WORKDIR /var/www/dokuwiki

RUN git checkout stable

RUN chown -R nginx:nginx /var/www/farm
RUN chown -R nginx:nginx /var/www/dokuwiki

VOLUME /var/www/farm
VOLUME /var/www/dokuwiki/data
VOLUME /var/www/dokuwiki/conf

EXPOSE 80 443

ENTRYPOINT ["/run.sh"]
