#!/bin/sh

#################################################
# AnripDdns v5.07.07
# Dynamic DNS using DNSPod API
# Edited by ProfFan
#################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/dns.conf

# Global Variables
# arPass=arMail=""

# Port IP
arIpAdress() {
    ipconfig getifaddr en6
}

# Get Domain IP
# arg: domain
arNslookup() {
    wget --quiet --output-document=- $inter$1
}

# Get data
# arg: type data
arApiPost() {
    local agent="AnripDdns/5.07(mail@anrip.com)"
    local inter="https://dnsapi.cn/${1:?'Info.Version'}"
    local param="login_email=${arMail}&login_password=${arPass}&format=json&${2}"
    wget --quiet --no-check-certificate --output-document=- --user-agent=$agent --post-data $param $inter
}

# Update
# arg: main domain  sub domain
arDdnsUpdate() {
    local domainID recordID recordRS recordCD myIP
    # Get domain ID
    domainID=$(arApiPost "Domain.Info" "domain=${1}")
    domainID=$(echo $domainID | sed 's/.\+{"id":"\([0-9]\+\)".\+/\1/')
    
    # Get Record ID
    recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
    recordID=$(echo $recordID | sed 's/.\+\[{"id":"\([0-9]\+\)".\+/\1/')
    
    # Update IP
    myIP=$(arIpAdress)
    recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_type=A&value=${myIP}&record_line=默认")
    recordCD=$(echo $recordRS | sed 's/.\+{"code":"\([0-9]\+\)".\+/\1/')

    # Output IP
    if [ "$recordCD" = "1" ]; then
        echo $recordRS | sed 's/.\+,"value":"\([0-9\.]\+\)".\+/\1/'
        return 1
    fi
    # Echo error message
    echo $recordRS | sed 's/.\+,"message":"\([^"]\+\)".\+/\1/'
}

# DDNS Check
# Arg: Main Sub
arDdnsCheck() {
    local postRS
    local hostIP=$(arIpAdress)
    local lastIP=$(arNslookup "${2}.${1}")
    echo "hostIP: ${hostIP}"
    echo "lastIP: ${lastIP}"
    if [ "$lastIP" != "$hostIP" ]; then
        postRS=$(arDdnsUpdate $1 $2)
        echo "postRS: ${postRS}"
        if [ $? -ne 1 ]; then
            return 0
        fi
    fi
    return 1
}

###################################################

# User

# DDNS
echo ${#domains[@]}
for index in ${!domains[@]}; do
    echo "${domains[index]} ${subdomains[index]}"
    arDdnsCheck "${domains[index]}" "${subdomains[index]}"
done