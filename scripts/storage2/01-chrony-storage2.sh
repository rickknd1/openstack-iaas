#!/bin/bash
# =============================================================================
# Script: 01-chrony-storage2.sh
# Description: Installe et configure Chrony (config standard OpenStack)
# A executer sur: ton COMPUTE transforme en Storage2
# =============================================================================

set -e

echo "=========================================="
echo "Installation de Chrony - Storage2"
echo "=========================================="

# =============================================================================
# 1. INSTALLATION
# =============================================================================
echo "[1/3] Installation de Chrony..."
apt update
apt install -y chrony

# =============================================================================
# 2. CONFIGURATION
# =============================================================================
echo "[2/3] Configuration de Chrony..."

cat > /etc/chrony/chrony.conf << 'EOF'
# Welcome to the chrony configuration file. See chrony.conf(5) for more
# information about usable directives.

# Include configuration files found in /etc/chrony/conf.d.
confdir /etc/chrony/conf.d

# This will use (up to):
# - 4 sources from ntp.ubuntu.com which some are ipv6 enabled
# - 2 sources from 2.ubuntu.pool.ntp.org which is ipv6 enabled as well
# - 1 source from [01].ubuntu.pool.ntp.org each (ipv4 only atm)
# This means by default, up to 6 dual-stack and up to 2 additional IPv4-only
# sources will be used.
# At the same time it retains some protection against one of the entries being
# down (compare to just using one of the lines). See (LP: #1754358) for the
# discussion.
#
# About using servers from the NTP Pool Project in general see (LP: #104525).
# Approved by Ubuntu Technical Board on 2011-02-08.
# See http://www.pool.ntp.org/join.html for more information.
#pool ntp.ubuntu.com        iburst maxsources 4
#pool 0.ubuntu.pool.ntp.org iburst maxsources 1
#pool 1.ubuntu.pool.ntp.org iburst maxsources 1
#pool 2.ubuntu.pool.ntp.org iburst maxsources 2

# Use time sources from DHCP.
sourcedir /run/chrony-dhcp

# Use NTP sources found in /etc/chrony/sources.d.
sourcedir /etc/chrony/sources.d

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Save NTS keys and cookies.
ntsdumpdir /var/lib/chrony

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can't be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3

# Get TAI-UTC offset and leap seconds from the system tz database.
# This directive must be commented out when using time sources serving
# leap-smeared time.
#leapsectz right/UTC

server controller iburst
EOF

# =============================================================================
# 3. DEMARRAGE
# =============================================================================
echo "[3/3] Demarrage de Chrony..."

systemctl restart chrony
systemctl enable chrony

sleep 3

echo ""
echo "Status de synchronisation:"
chronyc sources

echo "=========================================="
echo "Chrony configure!"
echo ""
echo "Note: ^* = synchronise, ^? = en attente"
echo ""
echo "PROCHAINE ETAPE: bash 02-swift-storage2.sh"
echo "=========================================="
