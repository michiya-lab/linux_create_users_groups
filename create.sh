#!/bin/bash

if [ $# -ne 1 ];
then
    echo "Invalid argument"
    exit 1
fi

if [ `id -u` -ne 0 ];
then
    echo "*** FATAL ERROR"
    echo " Please run as root"
fi

. functions/functions.sh

case "$1" in
"--users")
    create_users
;;
"--groups")
    create_groups
;;
*)
    echo "invalid argument"
;;
esac



