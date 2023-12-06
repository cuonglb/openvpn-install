#!/bin/bash

# Use this script to revoke client without deal with menu selection.
#
# Usage: sudo ./openvpn-revoke-client.sh <client_name>
# Example: sudo ./openvpn-revoke-client.sh foo

set -eu

function isRoot() {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
}

function tunAvailable() {
	if [ ! -e /dev/net/tun ]; then
		return 1
	fi
}

NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
if [[ $NUMBEROFCLIENTS == '0' ]]; then
	echo ""
	echo "You have no existing clients!"
	exit 1
fi

CLIENTS_NAME=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2)
CLIENT=$1

if [[ ${CLIENTS_NAME[@]} =~ $CLIENT ]]
then
  cd /etc/openvpn/easy-rsa/ || return
  ./easyrsa --batch revoke "$CLIENT"
  EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
  rm -f /etc/openvpn/crl.pem
  cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
  chmod 644 /etc/openvpn/crl.pem
  find /home/ -maxdepth 2 -name "$CLIENT.ovpn" -delete
  rm -f "/root/$CLIENT.ovpn"
  sed -i "/^$CLIENT,.*/d" /etc/openvpn/ipp.txt
  cp /etc/openvpn/easy-rsa/pki/index.txt{,.bk}
  echo ""
  echo "Certificate for client $CLIENT revoked."
else
  echo "Client name $CLIENT is not found"
fi