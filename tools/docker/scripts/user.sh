#!/bin/bash

Home_Dir=/var/www/html
if
        PATH=$(cat /etc/environment | grep HOME=$Home_Dir)
then
    echo "Current Home Directory already Set to $PATH"
else
    /bin/sed -i "s|HOME=/root|HOME=$Home_Dir|g" /etc/environment
    echo "Now, Current Home Directory Set to $Home_Dir"
fi
