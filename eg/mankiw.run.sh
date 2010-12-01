#!/bin/sh
APP_HOME=/home/httpd/apps/Hatena-Gearman/releases
exec 2>&1
exec \
  setuidgid apache \
  env - PATH="$APP_HOME:$PATH" \
  LC_ALL=C perl $APP_HOME/script/worker.pl
