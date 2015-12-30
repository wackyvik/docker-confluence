#!/bin/bash

# Prerequisities and checks start.

# --- Add /etc/hosts records
if [ -f /etc/hosts.install ]; then
    /bin/cat /etc/hosts.install >>/etc/hosts
fi

# --- Fix file permissions.
/usr/bin/find /var/atlassian/confluence -type d -exec /bin/chmod 750 '{}' ';'
/usr/bin/find /var/atlassian/confluence -type f -exec /bin/chmod 640 '{}' ';'
/usr/bin/find /usr/local/atlassian/confluence -type d -exec /bin/chmod 750 '{}' ';' 
/usr/bin/find /usr/local/atlassian/confluence -type f -exec /bin/chmod 640 '{}' ';'
/bin/chmod 755 /var/atlassian
/bin/chmod 755 /usr/local/atlassian
/bin/chmod 750 /usr/local/atlassian/confluence/bin/*
/bin/chown root:root /var/atlassian
/bin/chown root:root /usr/local/atlassian
/bin/chown -R confluence:confluence /var/atlassian/confluence
/bin/chown -R confluence:confluence /usr/local/atlassian/confluence

# --- Clean up the logs.
if [ ! -d /var/atlassian/confluence/logs ]; then
    /bin/rm -f /var/atlassian/confluence/logs >/dev/null 2>&1
    /bin/mkdir /var/atlassian/confluence/logs
    /bin/chown confluence:confluence /var/atlassian/confluence/logs
    /bin/chmod 750 /var/atlassian/confluence/logs
fi

if [ ! -e /var/atlassian/confluence/log ]; then
    /bin/ln -s /var/atlassian/confluence/logs /var/atlassian/confluence/log
    /bin/chown -h confluence:confluence /var/atlassian/confluence/log
fi

cd /var/atlassian/confluence/logs

for logfile in $(/usr/bin/find /var/atlassian/confluence/logs -type f | /bin/grep -Eiv '\.gz$'); do
    /usr/bin/gzip ${logfile}
    /bin/mv ${logfile}.gz ${logfile}-$(/usr/bin/date +%d%m%Y-%H%M%S).gz
done

for logfile in $(/usr/bin/find /var/atlassian/confluence/logs -type f -mtime +7); do
    /bin/echo "Startup logfile ${logfile} is older than 7 days. Removing it."
    /bin/rm -f ${logfile}
done

# --- Prepare environment variables.
if [ -f /usr/local/atlassian/confluence/conf/server.xml.template ]; then
    export CONFLUENCE_DB_DRIVER_ESCAPED=$(/bin/echo ${CONFLUENCE_DB_DRIVER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFLUENCE_DB_URL_ESCAPED=$(/bin/echo ${CONFLUENCE_DB_URL} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFLUENCE_DB_USER_ESCAPED=$(/bin/echo ${CONFLUENCE_DB_USER} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFLUENCE_DB_PASSWORD_ESCAPED=$(/bin/echo ${CONFLUENCE_DB_PASSWORD} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFLUENCE_FE_NAME_ESCAPED=$(/bin/echo ${CONFLUENCE_FE_NAME} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFLUENCE_FE_PORT_ESCAPED=$(/bin/echo ${CONFLUENCE_FE_PORT} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFLUENCE_FE_PROTO_ESCAPED=$(/bin/echo ${CONFLUENCE_FE_PROTO} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export CONFIGURE_FRONTEND_ESCAPED=$(/bin/echo ${CONFIGURE_FRONTEND} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    export CONFIGURE_SQL_DATASOURCE_ESCAPED=$(/bin/echo ${CONFIGURE_SQL_DATASOURCE} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g | sed -r s/'[ ]+'/''/g)
    
    if [ "${CONFIGURE_FRONTEND_ESCAPED}" != "TRUE" -a "${CONFIGURE_FRONTEND_ESCAPED}" != "true" ]; then 
        /bin/sed -r s/'proxyName="[^"]+" proxyPort="[^"]+" scheme="[^"]+" '//g /usr/local/atlassian/confluence/conf/server.xml.template >/usr/local/atlassian/confluence/conf/server.xml.template.2
        /bin/mv /usr/local/atlassian/confluence/conf/server.xml.template.2 /usr/local/atlassian/confluence/conf/server.xml.template
    fi
    
    if [ "${CONFIGURE_SQL_DATASOURCE_ESCAPED}" != "TRUE" -a "${CONFIGURE_SQL_DATASOURCE_ESCAPED}" != "true" ]; then 
        /bin/sed -r s/'<Resource name="jdbc\/confluence"'/'<!-- <Resource name="jdbc\/confluence" '/g /usr/local/atlassian/confluence/conf/server.xml.template | /bin/sed -r s/'validationQuery="Select 1" \/>'/'validationQuery="Select 1" \/> -->'/g >/usr/local/atlassian/confluence/conf/server.xml.template.2
        /bin/mv /usr/local/atlassian/confluence/conf/server.xml.template.2 /usr/local/atlassian/confluence/conf/server.xml.template
    fi
    
    /bin/cat /usr/local/atlassian/confluence/conf/server.xml.template | /bin/sed s/'\%CONFLUENCE_DB_DRIVER\%'/"${CONFLUENCE_DB_DRIVER_ESCAPED}"/g      \
                                                                      | /bin/sed s/'\%CONFLUENCE_DB_URL\%'/"${CONFLUENCE_DB_URL_ESCAPED}"/g            \
                                                                      | /bin/sed s/'\%CONFLUENCE_DB_USER\%'/"${CONFLUENCE_DB_USER_ESCAPED}"/g          \
                                                                      | /bin/sed s/'\%CONFLUENCE_DB_PASSWORD\%'/"${CONFLUENCE_DB_PASSWORD_ESCAPED}"/g  \
                                                                      | /bin/sed s/'\%CONFLUENCE_FE_NAME\%'/"${CONFLUENCE_FE_NAME_ESCAPED}"/g          \
                                                                      | /bin/sed s/'\%CONFLUENCE_FE_PORT\%'/"${CONFLUENCE_FE_PORT_ESCAPED}"/g          \
                                                                      | /bin/sed s/'\%CONFLUENCE_FE_PROTO\%'/"${CONFLUENCE_FE_PROTO_ESCAPED}"/g        \
                                                                      >/usr/local/atlassian/confluence/conf/server.xml
    
    /bin/chown confluence:confluence /usr/local/atlassian/confluence/conf/server.xml
    /bin/chmod 640 /usr/local/atlassian/confluence/conf/server.xml
    /bin/rm -f /usr/local/atlassian/confluence/conf/server.xml.template
fi

if [ -f /usr/local/atlassian/confluence/bin/setenv.sh.template ]; then
    export JAVA_MEM_MAX_ESCAPED=$(/bin/echo ${JAVA_MEM_MAX} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)
    export JAVA_MEM_MIN_ESCAPED=$(/bin/echo ${JAVA_MEM_MIN} | sed s/'\\'/'\\\\'/g | sed s/'\/'/'\\\/'/g | sed s/'('/'\\('/g | sed s/')'/'\\)'/g | sed s/'&'/'\\&'/g)

    /bin/cat /usr/local/atlassian/confluence/bin/setenv.sh.template | /bin/sed s/'\%JAVA_MEM_MIN\%'/"${JAVA_MEM_MIN_ESCAPED}"/g      \
                                                                    | /bin/sed s/'\%JAVA_MEM_MAX\%'/"${JAVA_MEM_MAX_ESCAPED}"/g      \
                                                                    >/usr/local/atlassian/confluence/bin/setenv.sh
    
    /bin/chown confluence:confluence /usr/local/atlassian/confluence/bin/setenv.sh
    /bin/chmod 750 /usr/local/atlassian/confluence/bin/setenv.sh
    /bin/rm -f /usr/local/atlassian/confluence/bin/setenv.sh.template
fi

# --- Prerequisities finished, all clear for takeoff.

# --- Environment variables.
export APP=confluence
export USER=confluence
export CONF_USER=confluence
export BASE=/usr/local/atlassian/confluence
export CATALINA_HOME="/usr/local/atlassian/confluence"
export CATALINA_BASE="/usr/local/atlassian/confluence"
export LANG=en_US.UTF-8

# --- Start Confluence
/usr/bin/su -m ${USER} -c "ulimit -n 63536 && cd $BASE && $BASE/bin/start-confluence.sh -fg"
