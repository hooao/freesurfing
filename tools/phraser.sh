#!/bin/bash

# subscribe and translate to clash.


usage() {
    echo "usage:"
}

ss() {
    # echo "enter ss with context $1"
    local sscontext=${1#*ss://}
    # echo $sscontext
    local encryptInfo=`echo "$sscontext" | awk -F '#' '{print $1}'`
    local serverInfo=`echo "$sscontext" | awk -F '#' '{print $2}'`
    # echo $encryptInfo
    # echo $serverInfo
    local serverAddr=`echo ${serverInfo#*@} | awk -F ':' '{print $1}'`
    local unbase64Encrypt=`echo "${encryptInfo}===="| fold -w 4 | sed '$ d' | tr -d '\n' | base64 -di`
    # echo $unbase64Encrypt
    local encryptMethod=`echo "$unbase64Encrypt" | awk -F ':' '{print $1}'`
    local serverPort=`echo "$unbase64Encrypt" | awk -F ':' '{print $3}'`
    local password=`echo "$unbase64Encrypt" | awk -F ':' '{print $2}' | awk -F '@' '{print $1}'`
    local serverIp=`echo "$unbase64Encrypt" | awk -F ':' '{print $2}' | awk -F '@' '{print $2}'`
    local server=
    echo "Summary for SS server $serverAddr($serverIp)"
    echo -e "\tencryptMethod: $encryptMethod"
    echo -e "\tserverPort: $serverPort"
    echo -e "\tpassword: $password"
    echo -e "\tEnd summary for server $serverAddr"

}

vmess() {
    # echo "enter vmess: $1"
    local vmesscontext=${1#*vmess://}
    local unbase64Encrypt=`echo "${vmesscontext}====" |fold -w 4| sed '$ d' | tr -d '\n' | base64 -di`
    # echo $unbase64Encrypt #json format here
    local serverPort=`echo $unbase64Encrypt | jq .port | sed 's/\"//g'`
    local serverIp=`echo $unbase64Encrypt | jq .add | sed 's/\"//g'`
    local serverId=`echo $unbase64Encrypt | jq .id | sed 's/\"//g'`
    local serverAid=`echo $unbase64Encrypt | jq .aid | sed 's/\"//g'`
    local serverType=`echo $unbase64Encrypt | jq .type | sed 's/\"//g'`
    local serverNet=`echo $unbase64Encrypt | jq .net | sed 's/\"//g'`
    local serverTls=`echo $unbase64Encrypt | jq .tls | sed 's/\"//g'`
    local serverAddr=`echo $unbase64Encrypt | jq .ps | sed 's/\"//g' | awk -F '@' '{print $2}' | awk -F ':' '{print $1}'`
    echo "Summary for SS server $serverAddr($serverIp)"
    echo -e "\tserverPort: $serverPort"
    echo -e "\tserverIp: $serverIp"
    echo -e "\tserverId: $serverId"
    echo -e "\tserverAid: $serverAid"
    echo -e "\tserverType: $serverType"
    echo -e "\tserverNet: $serverNet"
    echo -e "\tserverTls: $serverTls"
    echo -e "\tEnd summary for server $serverAddr"
}

translate() {
    # curl -s -L -oresult "$1"
    for line in `base64 -di result`; do
        if [[ $line == ss:\/\/* ]]; then
            ss $line
        elif [[ $line == vmess:\/\/* ]]; then
            vmess $line
        fi
    done

    
}




main() {
    translate $@

}

main $@