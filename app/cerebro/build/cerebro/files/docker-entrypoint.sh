#!/bin/sh

set -e

sed -i "s#CER_ES_URL#$CER_ES_URL#g" /opt/cerebro/conf/application.conf
sed -i "s#CER_ES_USER#$CER_ES_USER#g" /opt/cerebro/conf/application.conf
sed -i "s#CER_ES_PASSWORD#$CER_ES_PASSWORD#g" /opt/cerebro/conf/application.conf


exec $@ $CER_JAVA_OPTS

