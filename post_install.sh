#!/bin/sh

# The latest version of openHAB:
# Issues with version 3.0.1 regarding add-on installation, changing to latest snapshot version for now
#VERSION=$(fetch -qo - https://dl.bintray.com/openhab/mvn/org/openhab/distro/openhab/maven-metadata.xml | grep "<version>" | grep -Eo '[0-9\.]+' | head -n 1)
#OPENHAB_SOFTWARE_URL="https://dl.bintray.com/openhab/mvn/org/openhab/distro/openhab/${VERSION}/openhab-${VERSION}.tar.gz"

# The latest snapshot version of openHAB:
BASE_URL="https://ci.openhab.org/job/openHAB3-Distribution/lastSuccessfulBuild/"
OPENHAB_SOFTWARE_URL=$(fetch -qo - "${BASE_URL}api/xml?tree=artifacts[relativePath]{1}" | sed -n 's:.*<relativePath>\(.*\)</relativePath>.*:\1:p')
OPENHAB_SOFTWARE_URL="${BASE_URL}artifact/${OPENHAB_SOFTWARE_URL}"

# Switch to a temp directory for the openHAB download:
cd `mktemp -d -t openhab`

# Download the openHAB software (assuming acceptance of the EULA):
echo -n "Downloading the openHAB software..."
fetch ${OPENHAB_SOFTWARE_URL}
echo " done."

# Unpack the archive into the /usr/local/share directory:
echo -n "Installing openHAB in /usr/local/share..."
INSTALL_DIR="/usr/local/share/openhab3"
mkdir -p ${INSTALL_DIR} /config/persistence/db4o /config/persistence/rrd4j /config/persistence/mapdb /config/backups /config/home /config/log /config/userdata/etc/scripts /config/userdata/tmp /config/etc/openhab3
tar -xzvf openhab-*.tar.gz -C ${INSTALL_DIR}
echo " done."

# remove unnecessary files
rm openhab-*.tar.gz
rm -r ${INSTALL_DIR}/runtime/bin/contrib
rm ${INSTALL_DIR}/*.bat ${INSTALL_DIR}/runtime/bin/*.ps1 ${INSTALL_DIR}/runtime/bin/*.bat \
    ${INSTALL_DIR}/runtime/bin/*.psm1

# Create user
pw user add openhab -c openhab -u 235 -d /nonexistent -s /usr/bin/nologin

# Move openhab files to config directory
mv ${INSTALL_DIR}/conf/ /config/etc/openhab3/
mv ${INSTALL_DIR}/userdata/ /config/

# patch setenv
cd ${INSTALL_DIR}/runtime/bin/
patch < ${INSTALL_DIR}/runtime/bin/patch-runtime_bin_setenv

# make "openhab" the owner of the install location
chown -R openhab:openhab ${INSTALL_DIR} /config

#Set write permission to be able to write plugins update
chmod -R 755 ${INSTALL_DIR} /config/userdata /config/etc/openhab3 /config/log

# Start the services
chmod u+x /etc/rc.d/openhab3
sysrc -f /etc/rc.conf openhab3_enable="YES"
service openhab3 start

echo "openHAB successfully installed" > /root/PLUGIN_INFO
