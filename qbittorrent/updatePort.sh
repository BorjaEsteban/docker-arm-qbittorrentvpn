#! /bin/sh

# Source our persisted env variables from container startup
. /etc/qbittorrent/environment-variables.sh

# Settings
PIA_PASSWD_FILE=/userhome/openvpn-credentials.txt

pia_username=$(head -1 $PIA_PASSWD_FILE)
pia_passwd=$(tail -1 $PIA_PASSWD_FILE)
pia_client_id_file=/etc/qbittorrent/pia_client_id

#
# First get a port from PIA
#

new_client_id() {
    head -n 100 /dev/urandom | md5sum | tr -d " -" | tee $pia_client_id_file
}

pia_client_id="$(cat $pia_client_id_file 2>/dev/null)"
if [ -z ${pia_client_id} ]; then
     echo "Generating new client id for PIA"
     pia_client_id=$(new_client_id)
fi

# Get the port
port_assignment_url="http://209.222.18.222:2000/?client_id=$pia_client_id"
pia_response=$(curl -s -f $port_assignment_url)

# Check for curl error (curl will fail on HTTP errors with -f flag)
ret=$?
if [ $ret -ne 0 ]; then
     echo "curl encountered an error looking up new port: $ret"
fi

# Check for errors in PIA response
error=$(echo $pia_response | grep -oE "\"error\".*\"")
if [ ! -z "$error" ]; then
     echo "PIA returned an error: $error"
     exit
fi

# Get new port, check if empty
new_port=$(echo $pia_response | grep -oE "[0-9]+")
if [ -z "$new_port" ]; then
    echo "Could not find new port from PIA"
    exit
fi
echo "Got new port $new_port from PIA"

#
# Now, set port in qBittorrent
#

# TODO : injecter $new_port dans le fichier "/config/qBittorrent.conf" (le cr�er si n'existe pas)
#[Preferences]
#Connection\PortRangeMin=$new_port

