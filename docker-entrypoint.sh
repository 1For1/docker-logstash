#!/bin/bash

echo "----- Starting LOGSTASH -------"
logstash agent -f /etc/logstash/conf.d/logstash.conf

echo "------ Finished LOGSTASH ------"

exit 0