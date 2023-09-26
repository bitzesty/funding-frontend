#!/bin/sh

cd /home/app/deploy && exec bundle exec rails server -b 0.0.0.0 -p 3000 >>/var/log/puma.log 2>&1
