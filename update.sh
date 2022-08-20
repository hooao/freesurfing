#!/bin/bash

LATESTIPLIST="\
https://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest \
https://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest \
https://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-latest \
https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest "

TMP_DIR=$(mktemp -d /tmp/chinaip.XXXXXX)
LISTCOUNT=0

for list in $LATESTIPLIST; do
   if [[ $1 == "--debug" ]]; then
      echo "Download $list"
   else
      echo "Download $list"
      wget -q --no-check-certificate -O $TMP_DIR/ip.$LISTCOUNT $list
   fi
   let LISTCOUNT++
done
echo "Updating CN and US"

cat $TMP_DIR/ip.* | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" int(32-log($5)/log(2))}' | cat >$TMP_DIR/all_cn.txt
cat $TMP_DIR/ip.* | awk -F '|' '/US/&&/ipv4/ {print $4 "/" int(32-log($5)/log(2))}' | cat >$TMP_DIR/all_us.txt
sort -u $TMP_DIR/all_cn.txt | sed -r 's#(.+)#ip-cidr,\1, DIRECT#g' >freesurfing.ip
sort -u $TMP_DIR/all_cn.txt | sed -r 's#(.+)#IP-CIDR,\1, DIRECT#g' >freesurfing.surge
echo "freesurfing.chn"
sort -u $TMP_DIR/all_cn.txt | sed -r 's#(.+)#\1#g' >freesurfing.chn

sort -u $TMP_DIR/all_us.txt | sed -r 's#(.+)#ip-cidr,\1, PROXY#g' >freesurfing.us


rm -rf $TMP_DIR

echo "Updating gfwlist"
# if [[ $1 == "--debug" ]]; then
#    echo "updating dnsmasq"
# else
#    ./gfwlist2dnsmasq.sh -o freesurfing
# fi

diffcount=$(git diff freesurfing*  | wc -l)
if [ $diffcount != 0 ]; then
   echo "Something changed."
     git add freesurfing*
     git commit -m "update`date '+%Y%m%d%H%M'`"
   if [[ $1 != "--nopush" && $1 != "--debug" ]]; then
      git pull && git push
   fi
else
   echo "Nothing changed, exit."
fi
