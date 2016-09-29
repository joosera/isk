#!/usr/bin/env bash

function terminate {
  bundle exec ./isk-server.rb stop
  exit 0
}
trap 'terminate' TERM

bundle exec ./isk-server.rb start

tail -f /dev/null & wait

