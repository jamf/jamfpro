FROM tomcat:8.5.40-jre8-slim

LABEL Maintaner JamfDevops <devops@jamf.com>

RUN apt-get update -qq && \
	DEBIAN_FRONTEND=noninteractive apt-get install --ignore-missing --no-install-recommends -y jq curl && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	adduser --disabled-password --gecos '' tomcat && \
	rm -rf /usr/local/tomcat/webapps && \
	mkdir -p /usr/local/tomcat/webapps

COPY startup.sh /startup.sh
COPY log4j.stdout.replace /log4j.stdout.replace
COPY configuration.sh /configuration.sh

CMD ["/startup.sh"]

VOLUME /usr/local/tomcat/logs

EXPOSE 8080
