#!/bin/sh

cd /home/app/deploy && exec bundle exec rake jobs:work >>/var/log/workers.log 2>&1
