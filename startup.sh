#!/bin/bash

RUN_USER=${RUN_USER:=tomcat}
RUN_GROUP=${RUN_GROUP:=tomcat}

source /configuration.sh

if [ $? -gt 0 ]; then
	exit $?
fi

# Start Tomcat as the correct user.
if [ "${UID}" -eq 0 ]; then
    echo "User is currently root. Will change directory ownership to ${RUN_USER}:${RUN_GROUP}, then downgrade permission to ${RUN_USER}"
    PERMISSIONS_SIGNATURE=$(stat -c "%u:%U:%a" "${CATALINA_HOME}")
    EXPECTED_PERMISSIONS=$(id -u ${RUN_USER}):${RUN_USER}:700
    if [ "${PERMISSIONS_SIGNATURE}" != "${EXPECTED_PERMISSIONS}" ]; then
        echo "Updating permissions for CATALINA_HOME"
        chmod -R 700 "${CATALINA_HOME}" &&
        chown -R "${RUN_USER}:${RUN_GROUP}" "${CATALINA_HOME}"
    fi
    # Now drop privileges
    exec su -s /bin/bash "${RUN_USER}" -c "/usr/local/tomcat/bin/catalina.sh run"
else
    exec /usr/local/tomcat/bin/catalina.sh run
fi

