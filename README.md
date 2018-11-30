# JamfPro Tomcat Docker image [![Build Status](https://travis-ci.com/jamf/jamfpro.svg?branch=master)](https://travis-ci.com/jamf/jamfpro)

## Description
Basic Docker image based upon upstream Tomcat image to run a manually downloaded JamfPro ROOT.war from JamfNation

## Features
* Creates and runs Tomcat as user:group tomcat (non-root)
* Correct pathing for JamfPro file logs
* Logs to stdout of JamfPro logs in addtion to catalina logs
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

```

## Data Persistence
This image requires that either a `/data/ROOT.war` be bind-mounted and exist, or the `/usr/bin/tomcat/webapps/ROOT` directory exist.
A ROOT.war will be auto-unpacked and configured based upon the above environment variables, or if the ROOT directory already exists, nothing will be unpacked but logging paths, database information, JMX, and Java opts will be set.

## Example
Run a basic JamfPro instance with port 8080 exposed locally on port 8080, setup remote database, bind-mounted ROOT.war, and bind-mounted webapps directory

```
docker run -p 8080:8080 -d \
-e DATABASE_USERNAME=root \
-e DATABASE_PASSWORD=jamfsw03 \
-e DATABASE_HOST=host.docker.internal \
-v $(pwd)/ROOT.war:/data/ROOT.war \
-v $(pwd)/webapps:/usr/local/tomcat/webapps \
jamfpro
```