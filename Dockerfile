FROM logstash:latest

RUN /opt/logstash/bin/plugin update \
    && /opt/logstash/bin/plugin install logstash-patterns-core \
    && /opt/logstash/bin/plugin uninstall logstash-output-elasticsearch \
    && /opt/logstash/bin/plugin install logstash-output-elasticsearch