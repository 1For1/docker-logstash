FROM java:8-jre

# install plugin dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		libzmq3 \
	&& rm -rf /var/lib/apt/lists/*

# the "ffi-rzmq-core" gem is very picky about where it looks for libzmq.so
RUN mkdir -p /usr/local/lib \
	&& ln -s /usr/lib/*/libzmq.so.3 /usr/local/lib/libzmq.so

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV LOGSTASH_MAJOR 2.3
ENV LOGSTASH_VERSION 1:2.3.2-1

RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_MAJOR}/debian stable main" > /etc/apt/sources.list.d/logstash.list

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby
RUN ln -sf /usr/local/rvm/rubies/jruby-*/bin/jruby /usr/bin/jruby

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends logstash=$LOGSTASH_VERSION  \
	&& apt-get install -y sudo expect \
	&& rm -rf /var/lib/apt/lists/*

ENV PATH /opt/logstash/bin:$PATH


ADD docker-entrypoint.sh expect.logstash.update.conf /

#    && gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
#RUN curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby



#     && echo y | /opt/logstash/bin/logstash-plugin install logstash-codec-collectd \
#

RUN \
    expect -f expect.logstash.update.conf \
    && /opt/logstash/bin/logstash-plugin install logstash-patterns-core \
    && /opt/logstash/bin/logstash-plugin install logstash-output-elasticsearch \
    && /usr/bin/jruby -S gem install manticore -v '0.5.3' \
    && /usr/bin/jruby -S gem install jruby-httpclient \
    && curl http://apache.mirrors.hoobly.com//httpcomponents/httpclient/binary/httpcomponents-client-4.5-bin.tar.gz > /opt/logstash/vendor/jruby/lib/ruby/shared/httpcomponents-client-4.5-bin.tar.gz \
    && cd /opt/logstash/vendor/jruby/lib/ruby/shared \
    && tar -xzvf httpcomponents-client-4.5-bin.tar.gz

RUN echo "++++++++ MKDIR ++++++++"
WORKDIR /opt/logstash/vendor/jruby/lib/ruby/shared
RUN mkdir -p org/apache/httpcomponents/httpclient/4.5
RUN cp httpcomponents-client-4.5/lib/*.jar org/apache/httpcomponents/httpclient/4.5
RUN rm -rf httpcomponents-client-4.5

WORKDIR /

RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["logstash", "agent"]