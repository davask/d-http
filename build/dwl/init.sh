#!/bin/bash

cd ~/;

dwlDir="/dwl";

. ${dwlDir}/apache2.sh
echo ">> Apache2 initialized";

. ${dwlDir}/custom.sh
echo ">> custom initialized";

# . ${dwlDir}/senmail.sh
# sendmail is only available from davask/d-php*
if [ "`dpkg --get-selections | awk '{print $1}' | grep sendmail$ | wc -l`" == "1" ]; then
  sudo service sendmail start;
  echo ">> Sendmail initialized";
fi

tail -f /dev/null;
