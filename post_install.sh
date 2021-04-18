#!/bin/sh

# The latest version of openHAB:
VERSION=$(fetch -qo - https://dl.bintray.com/openhab/mvn/org/openhab/distro/openhab/maven-metadata.xml | grep "<version>" | grep -Eo '[0-9\.]+' | head -n 1)
OPENHAB_SOFTWARE_URL="https://dl.bintray.com/openhab/mvn/org/openhab/distro/openhab/${VERSION}/openhab-${VERSION}.tar.gz"

# Switch to a temp directory for the openHAB download:
cd `mktemp -d -t openhab`

# Download the openHAB software (assuming acceptance of the EULA):
echo -n "Downloading the openHAB software..."
fetch ${OPENHAB_SOFTWARE_URL}
echo " done."

# Unpack the archive into the /usr/local/share directory:
echo -n "Installing openHAB in /usr/local/share..."
mkdir /usr/local/share/openhab3
tar -xzvf openhab-*.tar.gz -C /usr/local/share/openhab3
echo " done."

# remove the package as it no longer needed
rm openhab-*.tar.gz

# Create user
pw user add openhab -c openhab -u 235 -d /nonexistent -s /usr/bin/nologin

# make "openhab" the owner of the install location
mkdir /config
chown -R openhab:openhab /usr/local/share/openhab3 /config

#Set write permission to be able to write plugins update
chmod 755 /usr/local/share/openhab3

# Start the services
chmod u+x /etc/rc.d/openhab3
sysrc -f /etc/rc.conf openhab3_enable="YES"
service openhab3 start

echo "openHAB successfully installed" > /root/PLUGIN_INFO
