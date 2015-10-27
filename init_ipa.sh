#!/bin/bash
#
# This script configures IPA client to create home dir for users and changes SUDO authority to IPA
# it should be run after installation of IPA client
# Maintainer: M3hran

DOMAIN=true;
STATIC=true;

function if_check {
	if grep -q static "/etc/network/interfaces"; then
		STATIC=true;
	else
		STATIC=false;
	fi

}


function hostname_check {

	if [[ $(hostname -f) == *.scientiamobile.local ]]; then
		DOMAIN=true;
	else
		DOMAIN=false;
	fi
}

if_check

if [ "$STATIC" == false ]; then

	printf "\nERROR: NIC must be statically defined.\n\n"
	exit
fi

hostname_check

apt-get update
apt-get -y install 'freeipa-client'
ipa-client-install



sed -i "\$a session     optional      pam_mkhomedir.so skel=/etc/skel umask=077" /etc/pam.d/common-auth
echo "skeleton file added.."
sed -Ei 's/^(.*services.*)/services = nss, pam, ssh, sudo/g' /etc/sssd/sssd.conf 
sed -i "\$a # configure SUDO and GSSAPI authentication\nsudo_provider = ldap\nldap_uri = ldap://id.scientiamobile.com\nldap_sudo_search_base = ou=sudoers,dc=scientiamobile,dc=local\nldap_sasl_mech = GSSAPI\nldap_sasl_authid = host/$(hostname -f)\nldap_sasl_realm = SCIENTIAMOBILE.LOCAL\nkrb5_server = id.scientiamobile.com\n" /etc/sssd/sssd.conf 
echo "SSSD configured..."


if [ "$FLAG" == false ]; then
	sed -i 's/exit 0//g' /etc/rc.local
	sed -i "\$a nisdomainname scientiamobile.local"  /etc/rc.local
	sed -i "\$a service sssd restart"  /etc/rc.local
	sed -i "\$a exit 0"  /etc/rc.local
	echo "nisdomainname added..."
fi

printf "Done.\n"
printf "WARNING: Reboot recommended!\n\n"
