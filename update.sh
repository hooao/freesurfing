#!/bin/sh

TMP_DIR=`mktemp -d /tmp/chinaip.XXXXXX`
echo "Updating china ip"
wget -q --no-check-certificate -O $TMP_DIR/ip http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest 
cat $TMP_DIR/ip | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}'|cat >$TMP_DIR/all_cn.txt

sort -u $TMP_DIR/all_cn.txt | sed -r 's#(.+)#ip-cidr,\1, DIRECT#g' > freesurfing.ip
cp $TMP_DIR/all_cn.txt ./
rm -rf $TMP_DIR

echo "Updating gfwlist"
./gfwlist2dnsmasq.sh -o freesurfing

diffcount=`git diff  freesurfing.ip freesurfing | wc -l`
if [ $diffcount != 0 ]; then
   echo "Something changed."
   git add freesurfing.ip freesurfing all_cn.txt
   git commit -m "update`date '+%Y%m%d%H%M'`"
   git pull && git push
else
   echo "Nothing changed, exit."
fi


