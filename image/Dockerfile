FROM ingensi/oracle-jdk:latest
MAINTAINER Viktor Larionov <larionov@viktor.ee>

VOLUME [ "/var/atlassian/confluence" ]

# Install required utilities.
RUN /usr/bin/yum install -y gzip   && \
    /usr/bin/yum install -y tar    && \
    /usr/bin/yum install -y bzip2

# Import certificates to JVM truststore.
ADD support-files/install.certificates /var/tmp/install.certificates
RUN for certificate_url in $(/bin/cat /var/tmp/install.certificates); do                                                   \
        certificate=/var/tmp/$(/bin/basename ${certificate_url});                                                          \
        /usr/bin/wget --progress=bar:force ${certificate_url} -O ${certificate};                                           \
        alias=$(/bin/basename ${certificate} | /bin/sed s/'\.pem'/''/g | /bin/sed s/'\.crt'/''/g);                         \
        /usr/java/default/bin/keytool -importcert -trustcacerts -file ${certificate} -alias ${alias} -keystore /etc/pki/ca-trust/extracted/java/cacerts -storepass changeit -storetype JKS -noprompt; \
        /usr/java/default/bin/keytool -importcert -trustcacerts -file ${certificate} -alias ${alias} -keystore /usr/java/default/jre/lib/security/cacerts -storepass changeit -storetype JKS -noprompt; \
        /bin/rm -f ${certificate};                                                                                         \
    done                                                                                                                && \
    /bin/rm -f /var/tmp/install.certificates

# Prepare the directory layout.
RUN /bin/mkdir -p /usr/local/atlassian/confluence && \
    /bin/mkdir -p /var/atlassian/confluence

# Creating user and group.
RUN /sbin/groupadd -g 9999 confluence                                                                                            && \
    /sbin/useradd -u 9999 -d /usr/local/atlassian/confluence -c "Atlassian Confluence" -g confluence -M -s /bin/bash confluence

# Install Confluence binaries from package.
ADD support-files/CONFLUENCE.VERSION /usr/local/atlassian/confluence/CONFLUENCE.VERSION
RUN VERSION=$(/bin/cat /usr/local/atlassian/confluence/CONFLUENCE.VERSION)                              && \
    /usr/bin/wget --progress=bar:force https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${VERSION}.tar.gz -O /var/tmp/atlassian-confluence-${VERSION}.tar.gz && \
    cd /var/tmp                                                                                         && \
    /usr/bin/tar -xvzf /var/tmp/atlassian-confluence-${VERSION}.tar.gz                                  && \
    /bin/cp -rfa /var/tmp/atlassian-confluence-${VERSION}/bin /usr/local/atlassian/confluence/          && \
    /bin/cp -rfa /var/tmp/atlassian-confluence-${VERSION}/conf /usr/local/atlassian/confluence/         && \
    /bin/cp -rfa /var/tmp/atlassian-confluence-${VERSION}/confluence /usr/local/atlassian/confluence/   && \
    /bin/cp -rfa /var/tmp/atlassian-confluence-${VERSION}/lib /usr/local/atlassian/confluence/          && \
    /bin/cp -rfa /var/tmp/atlassian-confluence-${VERSION}/webapps /usr/local/atlassian/confluence/      && \
    /bin/cp -rfa /var/tmp/atlassian-confluence-${VERSION}/work /usr/local/atlassian/confluence/         && \
    /bin/rm -rf /var/tmp/atlassian-confluence-${VERSION}                                                && \
    /bin/rm -rf /var/tmp/atlassian-confluence-${VERSION}.tar.gz

# Install Confluence RC scripts.
ADD support-files/install.hosts /etc/hosts.install
ADD support-files/confluence-init.sh /sbin/confluence-init.sh

# Create symlinks for correct layout.
RUN /bin/ln -s /var/tmp /usr/local/atlassian/confluence/temp                         && \
    /bin/ln -s /var/atlassian/confluence/logs /usr/local/atlassian/confluence/logs   && \
    /bin/ln -s /var/atlassian/confluence/logs /var/atlassian/confluence/log

# Install configuration overlay.
ADD conf-overlay/logging.properties /usr/local/atlassian/confluence/conf/
ADD conf-overlay/confluence-init.properties /usr/local/atlassian/confluence/confluence/WEB-INF/classes/confluence-init.properties
ADD conf-overlay/setenv.sh /usr/local/atlassian/confluence/bin/setenv.sh.template
ADD conf-overlay/server.xml /usr/local/atlassian/confluence/conf/server.xml.template

# ENTRYPOINT
RUN /bin/chown root:root /sbin/confluence-init.sh && \
    /bin/chmod 755 /sbin/confluence-init.sh
CMD /sbin/confluence-init.sh

# Expose default ports for Confluence.
EXPOSE 8090
