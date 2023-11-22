#!/bin/sh
#==============================================================================
# Entry point script to start a DnsPhpAdmin + Apache + PHP server
#==============================================================================
set -e

#=============================================================================
#
#  Variable declarations
#
#=============================================================================
SVER="20231119"			#-- Updated by Eugene Taylashev
#VERBOSE=1			#-- 1 - be verbose flag

#DIR_CONF=/etc/dnsphpadmin          #-- Configuration for Apache and DNSphpAdmin, could be mounted as a volume
#DIR_CODE=/var/dnaphpadmin          #-- Directory with DNSphpAdmin files


#=============================================================================
#
#  Function declarations
#
#=============================================================================
#-----------------------------------------------------------------------------
#  Output debugging/logging message
#------------------------------------------------------------------------------
dlog(){
  MSG="$1"
#  echo "$MSG" >>$FLOG
  [ $VERBOSE -eq 1 ] && echo "$MSG"
}
# function dlog


#-----------------------------------------------------------------------------
#  Output error message
#------------------------------------------------------------------------------
derr(){
  MSG="$1"
#  echo "$MSG" >>$FLOG
  echo "$MSG"
}
# function derr

#-----------------------------------------------------------------------------
#  Output good or bad message based on return status $?
#------------------------------------------------------------------------------
is_good(){
    STATUS=$?
    MSG_GOOD="$1"
    MSG_BAD="$2"
    
    if [ $STATUS -eq 0 ] ; then
        dlog "${MSG_GOOD}"
    else
        derr "${MSG_BAD}"
    fi
}
# function is_good

#-----------------------------------------------------------------------------
#  Output important parametrs of the container 
#------------------------------------------------------------------------------
get_container_details(){
    
    if [ $VERBOSE -eq 1 ] ; then
        echo '[ok] - getting container details:'
        echo '---------------------------------------------------------------------'

        #-- for Linux Alpine
        if [ -f /etc/alpine-release ] ; then
            OS_REL=$(cat /etc/alpine-release)
            echo "Alpine $OS_REL"
            apk -v info | sort
        fi

        uname -a
        ip address
        id apache
        echo '---------------------------------------------------------------------'
    fi
}
# function get_container_details


#=============================================================================
#
#  MAIN()
#
#=============================================================================
dlog '============================================================================='
dlog "[ok] - starting entrypoint.sh ver $SVER"

get_container_details


#-----------------------------------------------------------------------------
# Work with DNSphpAdmin
#-----------------------------------------------------------------------------
#-- Verify that configuration directory exists
if [ !  -d ${DIR_CONF} ] ; then

  #-- create the directory
  mkdir -p ${DIR_CONF}
  is_good "[ok] - created directory ${DIR_CONF}" \
    "[not ok] - creating directory ${DIR_CONF}"
else
  dlog "[ok] - directory $DIR_CONF exists"
fi

CONF_A2=/etc/apache2/httpd.conf

#-- Verify that Apache configuration file exists in the DIR_CONF
if [ ! -s ${DIR_CONF}/httpd.conf ] ; then

  #-- copy original
  cp $CONF_A2 ${DIR_CONF}/httpd.conf
  is_good "[ok] - copied httpd.conf" \
  "[not ok] - copying http.conf"

  #-- Change DocumentRoot
  sed -i -e "s|DocumentRoot \"/var/www/localhost/htdocs\"|DocumentRoot \"${DIR_CODE}\"|" \
        ${DIR_CONF}/httpd.conf
  is_good "[ok] - changed DocumentRoot to DNSphpAdmin for HTTP" \
      "[not ok] - changing DockumentRoot to DNSphpAdmin for HTTP"

  #-- Add directory params
  cat <<- EOC >>${DIR_CONF}/httpd.conf
<Directory "/var/dnsphpadmin">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
#    Require ip 10.0.0.0/8
</Directory>

#-- Add include instructions for custom DIR_CONF/ssl.conf
IncludeOptional /etc/dnsphpadmin/ssl.conf

EOC
      is_good "[ok] - updated HTTPD configuration file" \
        "[not ok] - updating HTTPD configuration file"

else
  dlog "[ok] - apache httpd.conf is in the config directory"

fi

#-- TLS Configuration: delete ssl.conf from conf.d if it exists in the DIR_CONF
if [ -s ${DIR_CONF}/ssl.conf ] ; then

  #-- remove the original
  rm /etc/apache2/conf.d/ssl.conf
  is_good "[ok] - removed the original ssl.conf" \
  "[not ok] - removing the original ssl.conf"

else
  dlog "[ok] - ssl.conf in the config directory and unique"

fi



CONF_D=/var/dnsphpadmin/config.php

#-- Verify that DNSphpAdmin configuration file exists in the DIR_CONF
if [ ! -s ${DIR_CONF}/config.php ] ; then

  #-- copy original
  cp /var/dnsphpadmin/config.default.php ${DIR_CONF}/config.php
  is_good "[ok] - copied config.php" \
  "[not ok] - copying config.php"
else
  dlog "[ok] - dnsphpadmin config.php is in the config directory"

fi

#-- Delete DNSphpAdmin configuration file
if [ -s $CONF_D ] ; then

  #-- remove it
  rm -f $CONF_D
fi

#-- Link DNSphpAdmin configuration file
if [ ! -e $CONF_D ] ; then
  #-- place soft-link
  ln -s ${DIR_CONF}/config.php $CONF_D
  is_good "[ok] - linked config.php" \
  "[not ok] - linking config.php"
else
  dlog "[ok] - dndphpadmin config.php is linked"
fi

#-- chanage ownership just in case
chown -R apache:apache ${DIR_CONF}
is_good "[ok] - verified owner for the app" \
  "[not ok] - verifying owner for the app"


#-- Redirect logs to stdout/stderr
ln -sf /dev/stdout /var/log/apache2/access.log && ln -sf /dev/stderr /var/log/apache2/error.log
is_good "[ok] - redirected HTTP logs for Docker" \
    "[not ok] - redirecting HTTP logs for Docker"
ln -sf /dev/stdout /var/log/apache2/ssl_access.log && ln -sf /dev/stderr /var/log/apache2/ssl_error.log
is_good "[ok] - redirected HTTPS logs for Docker" \
    "[not ok] - redirecting HTTPS logs for Docker"

#-- Apache gets grumpy about PID files pre-existing
rm -f /run/apache2/httpd.pid

#-- Check configuration
httpd -t -f ${DIR_CONF}/httpd.conf
is_good "[ok] - Apache HTTPD configuration is good" \
    "[not ok] - Apache HTTPD configuration is NOT good"

dlog "[ok] - strating Apache HTTPD: "
exec httpd -E /dev/stderr -f ${DIR_CONF}/httpd.conf -DFOREGROUND "$@"
derr "[not ok] - finish of entrypoint.sh"

