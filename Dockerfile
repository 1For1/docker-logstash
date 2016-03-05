FROM logstash:latest

RUN /opt/logstash/bin/plugin update \
    && /opt/logstash/bin/plugin install logstash-patterns-core