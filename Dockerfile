FROM logstash:latest

RUN apt-get update \
    && apt-get install -y jruby ruby \
    && /opt/logstash/bin/plugin update \
    && /opt/logstash/bin/plugin install logstash-patterns-core \
    && /opt/logstash/bin/plugin install logstash-output-elasticsearch