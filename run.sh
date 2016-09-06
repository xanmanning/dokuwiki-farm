#!/bin/bash

VOLUMEDIR=(conf data inc)

# Are our volumes empty? If so set them up.
for VDIR in ${VOLUMEDIR[@]} ; do
    if [ "$(ls -A /var/www/dokuwiki/${VDIR} | grep -v '.gitignore')" ] ; then
        echo "${VDIR} is not empty. Skipping..."
    else
        rsync -arvvlPHS /tmp/${VDIR}/ /var/www/dokuwiki/${VDIR}/
    fi
done

# Is our farm empty? if so set it up.
if [ "$(ls -A /var/www/farm | grep -v '.gitignore')" ] ; then
    echo "farm directory not empty. Skipping..."
else
    rsync -arvvlPHS /tmp/farm/ /var/www/farm/
fi

# Do we need a git pull?
if [ ${DW_GIT_PULL} ] ; then
    git --git-dir=/var/www/dokuwiki/.git --work-tree=/var/www/dokuwiki \
        pull origin stable
fi

# Are we using shared sign on?
if [ ${DW_SSO} ] ; then
    if [ "$(grep 'users.auth.php' /var/www/dokuwiki/inc/preload.php)" ] ; then
        echo "Aleady have single sign on."
    else
        echo "Enabling single-sign on."
        echo "\$config_cascade['plainauth.users'] = array('default' => '/var/www/dokuwiki/conf/users.auth.php',);" >> /var/www/dokuwiki/inc/preload.php
    fi
fi

# Run our daemon.
/usr/bin/supervisord -n -c /etc/supervisord.conf
