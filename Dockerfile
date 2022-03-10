FROM tomcat:8.5.73-jdk11-openjdk-slim-buster

LABEL Maintainer JamfDevops <devops@jamf.com>

RUN apt-get update -qq && \
	DEBIAN_FRONTEND=noninteractive apt-get install --ignore-missing --no-install-recommends -y jq curl unzip && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	adduser --disabled-password --gecos '' tomcat && \
	rm -rf /usr/local/tomcat/webapps && \
	mkdir -p /usr/local/tomcat/webapps

COPY startup.sh /startup.sh
COPY log4j.stdout.replace /log4j.stdout.replace
COPY log4j2.stdout.appenders.replace /log4j2.stdout.appenders.replace
COPY log4j2.stdout.loggers.analytics.replace /log4j2.stdout.loggers.analytics.replace
COPY log4j2.stdout.loggers.root.replace /log4j2.stdout.loggers.root.replace
COPY log4j2.stdout.loggers.vpp.replace /log4j2.stdout.loggers.vpp.replace
COPY configuration.sh /configuration.sh

CMD ["/startup.sh"]

VOLUME /usr/local/tomcat/logs

EXPOSE 8080
