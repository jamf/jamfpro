# JamfPro Tomcat Docker image [![Build Status](https://travis-ci.com/jamf/jamfpro.svg?branch=master)](https://travis-ci.com/jamf/jamfpro)

## Description
Basic example Docker image based upon upstream Tomcat image to run a manually downloaded JamfPro ROOT.war from JamfNation.

## Note
This repository is provided as an example of how to construct a very basic Docker image to run a JamfPro server.
Please refer to this JamfNation post - [Apache Tomcat Versions Installed by the Jamf Pro Installer](https://www.jamf.com/jamf-nation/articles/380/apache-tomcat-versions-installed-by-the-jamf-pro-installer) - to determine which Tomcat versions are explictly supported for a particular version of JamfPro.

## Features
* Creates and runs Tomcat as user:group tomcat (non-root)
* Correct pathing for JamfPro file logs
* Logs to stdout of JamfPro logs in addition to catalina logs
* JMX connection information
* Remote database connection in DataBase.xml

## Environment Variable Options
```
STDOUT_LOGGING [ true ] / false

DATABASE_HOST [ localhost ]
DATABASE_NAME [ jamfsoftware ]
DATABASE_USERNAME [ jamfsoftware ]
DATABASE_PASSWORD [ jamfsw03 ]
DATABASE_PORT [ 3306 ]

JMXREMOTE true / [ false ]
JMXREMOTE_PORT
JMXREMOTE_RMI_PORT
JMXREMOTE_SSL
JMXREMOTE_AUTHENTICATE
RMI_SERVER_HOSTNAME
JMXREMOTE_PASSWORD_FILE

CATALINA_OPTS
JAVA_OPTS [ -Djava.awt.headless=true ]

PRIMARY_NODE_NAME -- Enable clustering
  This MUST be the ip address of the primary as recognized by Tomcat
  There is no direct JamfPro primary <--> secondary communication so the ip need not be reachable by the secondary directly

POD_NAME -- Enable Kubernetes clustering via downward API
POD_IP -- Enable Kubernetes clustering via downward API

MEMCACHED_HOST -- Enable Memcached caching, assumes port 11211 by default

```

## Data Persistence
This image requires that either a `/data/ROOT.war` be bind-mounted and exist, or the `/usr/bin/tomcat/webapps/ROOT` directory exist.
A ROOT.war will be auto-unpacked and configured based upon the above environment variables, or if the ROOT directory already exists, nothing will be unpacked but logging paths, database information, JMX, and Java opts will be set.

## Example
Run a basic JamfPro instance with port 8080 exposed locally on port 8080, setup remote database, bind-mounted ROOT.war, and bind-mounted webapps directory.

```
docker run -p 8080:8080 -d \
-e DATABASE_USERNAME=root \
-e DATABASE_PASSWORD=jamfsw03 \
-e DATABASE_HOST=host.docker.internal \
-v $(pwd)/ROOT.war:/data/ROOT.war \
-v $(pwd)/webapps:/usr/local/tomcat/webapps \
jamfdevops/jamfpro:0.0.8
```
Valid image tags can be found on  [Dockerhub Tags](https://hub.docker.com/r/jamfdevops/jamfpro/tags/) or [Github Releases](https://github.com/jamf/jamfpro/releases).


## Kubernetes Deployment
When enabling clustering the Tomcat manifest should include both `POD_NAME` and `POD_IP` environment variables which can be accessed via the Kubernetes downward API.  The environment variable `PRIMARY_NODE_NAME` should be set to whichever pod will become the primary node.  An example of utilizing the downward API in a manifest:
```
- name: POD_NAME
valueFrom:
  fieldRef:
    fieldPath: metadata.name
- name: POD_IP
valueFrom:
  fieldRef:
    fieldPath: status.podIP
```
