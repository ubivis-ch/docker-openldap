#!/bin/sh

# When not setting this, running slapd failes (with core dump)
ulimit -n 1024

if [ "$1" == "ssha" ]; then
    if [ "$#" -eq 2 ]; then
        plain="$2"
    else
        read -p "Password (hidden): " -s plain
        echo ""
    fi

    echo -n "Password hash: "
    slappasswd -s "${plain}"
    
    exit 0
fi

config_ldif=/etc/openldap/slapd.ldif
config_dir=/etc/openldao/slapd.d
config_log=/tmp/config.log

user=ldap
group=ldap

if [ -z "${OPENLDAP_DOMAIN}" ]; then
    echo "Error: Missing mandatory OPENLDAP_DOMAIN!"
    exit 1
fi

dc_string="dc=$(echo ${OPENLDAP_DOMAIN} | sed 's/\./,dc=/g')"

OPENLDAP_USERNAME="${OPENLDAP_USERNAME:-admin}"

root_dn="cn=${OPENLDAP_USERNAME},${dc_string}"

if [ -z "${OPENLDAP_PASSWORD}" ]; then
    root_dn_password=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
    root_dn_password_hash=`slappasswd -s "${root_dn_password}"`
    
    echo "Password for RootDN (${root_dn}): ${root_dn_password}"
else
    if [ "${OPENLDAP_PASSWORD}" = "{SSHA}"* ]; then
        root_dn_password_hash="${OPENLDAP_PASSWORD}"
    else
        root_dn_password="${OPENLDAP_PASSWORD}"
        root_dn_password_hash=`slappasswd -s "${root_dn_password}"`
    fi    
fi

root_dn_password_hash_sed_safe=${root_dn_password_hash//\//\\\/}

sed -i "s/\(olcRootDN:\).*/\1 ${root_dn}/" $config_ldif
sed -i "s/\(olcRootPW:\).*/\1 ${root_dn_password_hash_sed_safe}/" $config_ldif

sed -i "s/\(#\tby anonymous auth\)/\1\nolcAccess: to * by self write by users read by anonymous auth/" $config_ldif

if [ -n "${OPENLDAP_SCHEMAS}" ]; then
    schemas="$(echo ${OPENLDAP_SCHEMAS} | sed 's/,/\n/g' | sort -u)"

    include_string=""

    for schema in $schemas; do
        schema_path="/etc/openldap/schema/${schema}.ldif"
        
        if [ ! -f "${schema_path}" ]; then
            echo "ERROR: Unknown schema \"${schema}\"!"
            exit 1
        fi
       
        if ! grep -q "${schema_path}" $config_ldif; then
            include_string="${include_string}\ninclude: file://${schema_path}"
        fi
    done
    
    include_string_sed_safe=${include_string//\//\\\/}
    
    sed -i "s/\(nis\.ldif\)/\1${include_string_sed_safe}/" $config_ldif
fi

if [ -n "${OPENLDAP_OVERLAYS}" ]; then
    overlays="$(echo ${OPENLDAP_OVERLAYS} | sed 's/,/\n/g' | sort -u)"

    include_string=""

    for overlay in $overlays; do
        overlay_file="${overlay}.so"
        overlay_path="/usr/lib/openldap/${overlay_file}"
        overlay_config="/etc/openldap/overlayconfig/${overlay}.ldif"
        
        if [ ! -f "${overlay_path}" ]; then
            echo "ERROR: Unknown overlay \"${overlay}\"!"
            exit 1
        fi
       
        if ! grep -q -r "^olcModuleload:\s*${overlay_file}" $config_ldif; then
            include_string="${include_string}\nolcModuleload: ${overlay_file}"
        fi
        
        if [ -f "${overlay_config}" ]; then
            echo "" >> $config_ldif
            cat $overlay_config >> $config_ldif
        fi
    done
    
    include_string_sed_safe=${include_string//\//\\\/}

    sed -i "s/\(back_mdb\.so\)/\1${include_string_sed_safe}/" $config_ldif
fi

sed -i "s/dc=my-domain,dc=com/${dc_string}/g" $config_ldif

sed -i "s/openldap\/openldap-data/openldap/" $config_ldif

# Used for debugging ...
#cat $config_ldif
#exit 1

mkdir -p $config_dir
rm -rf $config_dir/*

slapadd -n 0 -F $config_dir -l $config_ldif >$config_log 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Initial configuration failed!"
    sed -i -e 's/^/  | /' $config_log
    cat $config_log
    exit 1
fi

rm $config_log

chown -R $user:$group $config_dir

if [ "$#" -gt 0 ]; then
    exec "$@"
else
    slapd -d 32768 -u $user -g $group -F $config_dir
fi
