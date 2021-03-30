#!/bin/bash
set -e
cd `dirname $0`

echo "[broker]"
terraform output brokers | grep "=" | sed "s/.*\"\(.*\)\" = .*/\1/"
echo
echo "[client]"
terraform output clients | grep "=" | sed "s/.*\"\(.*\)\" = .*/\1/"
echo
echo "[prometheus]"
terraform output prometheus-ip | sed "s/\"//g"
echo
echo "[zookeeper]"
terraform output zookeepers | grep "=" | sed "s/.*\"\(.*\)\" = .*/\1/"
