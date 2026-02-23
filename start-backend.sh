#!/usr/bin/env bash
set -e
# sudo /usr/sbin/lsof -ti tcp:8091 | sudo xargs kill -9 || true
cd "/Users/licheng/Desktop/harmoney-mail/servers"
exec ./gradlew bootRun
