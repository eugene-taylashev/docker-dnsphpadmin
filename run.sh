#!/usr/bin/env bash
#-------------------------------------------------------------------------------
#  Sample script to run the DNSphpAdmin image with params
#-------------------------------------------------------------------------------

#-- Main settings
IMG_NAME=dnsphpadmin        #-- container/image name
VERBOSE=1                #-- 1 - be verbose flag
SVER="20231119"

#-- Check architecture
[[ $(uname -m) =~ ^armv7 ]] && ARCH="armv7-" || ARCH=""

source functions.sh      #-- Use common functions

stop_container   $IMG_NAME
remove_container $IMG_NAME

docker run -d \
  --name $IMG_NAME \
  -p 8080:80/tcp \
  -p 8445:443/tcp \
  -v ./test-conf:/etc/dnsphpadmin \
  -e VERBOSE=${VERBOSE} \
etaylashev/dnsphpadmin:${ARCH}latest

exit 0
