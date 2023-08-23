#!/bin/bash

# Database migration

echo 'prepping database'

bin/rails db:setup

bin/rails db:migrate

# Runs rails server

echo 'running server'

bundle exec rails server -b 0.0.0.0 -p 3000