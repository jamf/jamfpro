ARG TOMCAT_VERSION=9.0.85-jdk21
FROM tomcat:$TOMCAT_VERSION

LABEL Maintainer JamfDevops <devops@jamf.com>

RUN apt-get update -qq && \
	DEBIAN_FRONTEND=noninteractive apt-get install --ignore-missing --no-install-recommends -y jq curl unzip && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	adduser --disabled-password --gecos '' tomcat && \
	rm -rf /usr/local/tomcat/webapps && \
	mkdir -p /usr/local/tomcat/webapps && \
	mkdir /jamfpro-config && \
	chmod -R o+w /usr/local/tomcat/webapps && \
	chmod go+r /usr/local/tomcat/conf /usr/local/tomcat/conf/server.xml


COPY startup.sh /startup.sh
COPY log4j.stdout.replace /log4j.stdout.replace
COPY log4j2.stdout.appenders.replace /log4j2.stdout.appenders.replace
COPY log4j2.stdout.loggers.analytics.replace /log4j2.stdout.loggers.analytics.replace
COPY log4j2.stdout.loggers.root.replace /log4j2.stdout.loggers.root.replace
COPY log4j2.stdout.loggers.vpp.replace /log4j2.stdout.loggers.vpp.replace
COPY server.template /jamfpro-config/server.template
COPY configuration.sh /configuration.sh

CMD ["/startup.sh"]

VOLUME /usr/local/tomcat/logs

EXPOSE 8080
