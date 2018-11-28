FROM tomcat:8.5.35-jre8-slim

LABEL Maintaner JamfDevops <devops@jamf.com>

RUN adduser --disabled-password --gecos '' tomcat && \
	rm -rf /usr/local/tomcat/webapps && \
	mkdir -p /usr/local/tomcat/webapps

COPY startup.sh /startup.sh
COPY log4j.stdout.replace /log4j.stdout.replace
COPY configuration.sh /configuration.sh

CMD ["/startup.sh"]

VOLUME /usr/local/tomcat/logs

EXPOSE 8080
