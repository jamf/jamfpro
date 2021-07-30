#!/bin/bash -e

##########################################################
####################### Functions ########################
echo_time() {
    date +"%Y-%m-%d %T %z $(printf "%b " "$@" | sed 's/%/%%/g')"
}

unpack_root_war() {
  if [ ! -f /data/ROOT.war ]; then
    echo_time "FATAL ERROR: No ROOT.war to unpack, cannot continue
    Mount ROOT.war to /data/ROOT.war"
    exit 1
  fi
  #Unpack the warfile
  echo_time "Unpacking ROOT.war to /usr/local/tomcat/webapps/ROOT \n"
  unzip -q /data/ROOT.war -d /usr/local/tomcat/webapps/ROOT
}

setup_linux_logging_paths() {
  #Replace Mac logging paths with linux based paths
  echo_time "Set logging file paths to use linux file paths"
  #Check whether log4j.properties (<= Jamf Pro 10.30.3) or log4j2.xml (>= Jamf Pro 10.31.0) exists
  FILE=/usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j.properties
  if test -f "$FILE"; then
    sed -i s#/Library/JSS/Logs#/usr/local/tomcat/logs# /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j.properties
  else
    sed -i s#/Library/JSS/Logs#/usr/local/tomcat/logs# /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j2.xml
  fi
}

setup_stdout_logging() {
  STDOUT_LOGGING=${STDOUT_LOGGING:-true}
  if [[ $STDOUT_LOGGING == "true" ]]; then
    #Add stdout output for Jamf specific log files while maintaining logging to the files
    echo_time "STDOUT_LOGGING is true, add stdout logging for all logfiles"
    #Check whether log4j.properties (<= Jamf Pro 10.30.3) or log4j2.xml (>= Jamf Pro 10.31.0) exists
    FILE=/usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j.properties
    if test -f "$FILE"; then
      echo_time "Found log4j.properties, enable logging to stdout"
      if grep -Fxq "log4j.rootLogger=INFO,JAMF,stdout" /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j.properties; then
        echo_time "stdout logging appears to be present in log4j.properties file, skipping"
      else
        echo_time "Add stdout logging to log4j.properties file"
        sed -e '/log4j.rootLogger/ {r /log4j.stdout.replace
          d}' -i /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j.properties
      fi
    else
      echo_time "Found log4j2.xml, enable logging to stdout"
      if grep -Fxq '        <Console name="Console" target="SYSTEM_OUT">' /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j2.xml; then
        echo_time "stdout logging appears to be present in log4j2.xml file, skipping"
      else
        echo_time "Add stdout logging to log4j2.xml file"
        sed -e '/<Appenders>/ {r /log4j2.stdout.appenders.replace
          d}' -i /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j2.xml
        sed -e '/<Root level="info" includeLocation="false">/ {r /log4j2.stdout.loggers.root.replace
          d}' -i /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j2.xml
        sed -e '/<Logger name="com.jamfsoftware.analytics.file" level="info" additivity="false" includeLocation="false">/ {r /log4j2.stdout.loggers.analytics.replace
          d}' -i /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j2.xml
        sed -e '/<AppenderRef ref="JAMFVPP"\/>/ {r /log4j2.stdout.loggers.vpp.replace
          d}' -i /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/log4j2.xml
      fi
    fi
  fi
}

setup_remote_database() {
  DATABASE_HOST=${DATABASE_HOST:-localhost}
  DATABASE_NAME=${DATABASE_NAME:-jamfsoftware}
  DATABASE_USERNAME=${DATABASE_USERNAME:-jamfsoftware}
  DATABASE_PASSWORD=${DATABASE_PASSWORD:-jamfsw03}
  DATABASE_PORT=${DATABASE_PORT:-3306}

  echo_time "\n\nDatabase connection information: \n DATABASE_HOST: ${DATABASE_HOST} \n DATABASE_NAME: ${DATABASE_NAME} \n DATABASE_USERNAME: ${DATABASE_USERNAME}\n\n"

  echo_time "Setting up the DataBase.xml file to use remote MySQL database"
  if [ ! -f "/usr/local/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml" ]; then
    echo_time "FATAL ERROR: DataBase.xml not where expected, cannot continue"
    exit 1
  else
    sed -i s#\<ServerName.*#\<ServerName\>$DATABASE_HOST\</ServerName\># /usr/local/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml
    sed -i s#\<DataBaseName.*#\<DataBaseName\>$DATABASE_NAME\</DataBaseName\># /usr/local/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml
    sed -i s#\<DataBaseUser.*#\<DataBaseUser\>$DATABASE_USERNAME\</DataBaseUser\># /usr/local/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml
    sed -i s#\<DataBasePassword.*#\<DataBasePassword\>$DATABASE_PASSWORD\</DataBasePassword\># /usr/local/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml
    sed -i s#\<ServerPort.*#\<ServerPort\>$DATABASE_PORT\</ServerPort\># /usr/local/tomcat/webapps/ROOT/WEB-INF/xml/DataBase.xml
  fi
}

setup_jmx_remote_opts() {
  JMXREMOTE_OPTS=${JMXREMOTE_OPTS:-}
  JMXREMOTE=${JMXREMOTE:-false}
  
  if [[ $JMXREMOTE == "true" ]]; then
    echo_time "JMX is set to enabled, parsing environment variable settings"
    JMXREMOTE_PORT=${JMXREMOTE_PORT:-}
    JMXREMOTE_RMI_PORT=${JMXREMOTE_RMI_PORT:-}
    JMXREMOTE_SSL=${JMXREMOTE_SSL:-}
    JMXREMOTE_AUTHENTICATE=${JMXREMOTE_AUTHENTICATE:-}
    RMI_SERVER_HOSTNAME=${RMI_SERVER_HOSTNAME:-}
    JMXREMOTE_PASSWORD_FILE=${JMXREMOTE_PASSWORD_FILE:-}

    echo_time "\n\nJMX connection information:\n JMXREMOTE: ${JMXREMOTE} \n JMXREMOTE_PORT: ${JMXREMOTE_PORT} \n JMXREMOTE_RMI_PORT: ${JMXREMOTE_RMI_PORT} \n JMXREMOTE_SSL: ${JMXREMOTE_SSL} \n JMXREMOTE_AUTHENTICATE: ${JMXREMOTE_AUTHENTICATE} \n RMI_SERVER_HOSTNAME: ${RMI_SERVER_HOSTNAME} \n JMXREMOTE_PASSWORD_FILE: ${JMXREMOTE_PASSWORD_FILE} \n\n"

    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Dcom.sun.management.jmxremote"
    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Dcom.sun.management.jmxremote.port=${JMXREMOTE_PORT}"
    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMXREMOTE_RMI_PORT}"
    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Dcom.sun.management.jmxremote.ssl=${JMXREMOTE_SSL}"
    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Dcom.sun.management.jmxremote.authenticate=${JMXREMOTE_AUTHENTICATE}"
    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Djava.rmi.server.hostname=${RMI_SERVER_HOSTNAME}"
    JMXREMOTE_OPTS="${JMXREMOTE_OPTS} -Dcom.sun.management.jmxremote.password.file=${JMXREMOTE_PASSWORD_FILE}"
  fi
}

setup_java_opts() {
  echo_time "Setting CATALINA_OPTS and JAVA_OPTS"

  CATALINA_OPTS=${CATALINA_OPTS:-}
  JAVA_OPTS=${JAVA_OPTS:-"-Djava.awt.headless=true"}

  export JAVA_OPTS="${JAVA_OPTS} ${CATALINA_OPTS} ${JMXREMOTE_OPTS}"

  echo_time "\n\nJAVA_OPTS: ${JAVA_OPTS} \n\n"
}

create_cache_properties(){
  echo_time "Setting up the cache.properties to be memcached"
  cat <<-EOF > /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/dal/cache.properties
cache.type=memcached
EOF
}

create_memcached_properties(){
  echo_time "Setting up the memcached.properties"
  cat <<-EOF > /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/dal/memcached.properties
memcached.endpoints[0]=$MEMCACHED_HOST
memcached.timeToLiveSeconds=120
EOF
}

##########################################################
# Arguments:
#   Cluster primary node name / ip
##########################################################
create_cluster_properties() {
  echo_time "Creating the clustering properties file"
cat <<- EOF > /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/clustering.properties
cluster.settings.enabled=true
cluster.settings.monitor_frequency=180
cluster.node[0]=$1
EOF
}


##########################################################
####################### Executions #######################

echo_time "Check if Tomcat ROOT directory exists, will NOT overwrite if exists"
if [ ! -d /usr/local/tomcat/webapps/ROOT ]; then
  echo_time "/usr/local/tomcat/webapps/ROOT directory does not exist, attempt to deploy ROOT.war from /data"
  unpack_root_war

else
  echo_time "/usr/local/tomcat/webapps/ROOT exists, skipping ROOT.war deploy"
fi

# Check to see if clustering should be enabled by existence of PRIMARY_NODE_NAME
if [ -n "$PRIMARY_NODE_NAME" ]; then
  echo_time "Primary node name is set, enable clustering with primary set to: ${PRIMARY_NODE_NAME}"
  
  # Check to see if this is a Kubernetes deployment with POD_NAME and POD_IP set
  if [ -n "$POD_NAME" ] && [ -n "$POD_IP" ]; then
    echo_time "POD_NAME and POD_IP set, assuming Kubernetes environment"
  
    # Check to see if the primary node name requested is the current pod name, if so set this as primary
    if [[ "${PRIMARY_NODE_NAME}" == "${POD_NAME}" ]]; then
      echo_time "This node should be the primary node, setting paramaters accordingly"
      create_cluster_properties "${POD_IP}"
    else
      echo_time "This node will be setup as secondary node"
    fi
  else
    # Primary node name set but no pod name or pod ip set
    create_cluster_properties "${PRIMARY_NODE_NAME}"
  fi
fi

# Check for MEMCACHED_HOST environment variable to setup Memcached
if [ -n "$MEMCACHED_HOST" ]; then
  echo_time "Memcached host is set, setup memcached settings"
  create_cache_properties

  create_memcached_properties
fi

setup_stdout_logging

setup_linux_logging_paths

setup_remote_database

setup_jmx_remote_opts

setup_java_opts


##########################################################
