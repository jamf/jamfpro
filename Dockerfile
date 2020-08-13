FROM tomcat:8.5.57-jdk11-corretto

LABEL Maintainer JamfDevops <devops@jamf.com>

RUN yum -y update && \
	yum -y install jq curl unzip && \
	yum clean all && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	yum -y install util-linux && \
	yum -y install shadow-utils && \
	useradd -U tomcat && usermod --lock --expiredate 1 tomcat &&  \
	rm -rf /usr/local/tomcat/webapps && \
	mkdir -p /usr/local/tomcat/webapps

COPY startup.sh /startup.sh
COPY log4j.stdout.replace /log4j.stdout.replace
COPY configuration.sh /configuration.sh

CMD ["/startup.sh"]

VOLUME /usr/local/tomcat/logs

EXPOSE 8080