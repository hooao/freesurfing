#!/bin/sh

TMP_DIR=`mktemp -d /tmp/chinaip.XXXXXX`

wget -q --no-check-certificate -O $TMP_DIR/ip http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest 
cat $TMP_DIR/ip | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}'|cat >$TMP_DIR/all_cn.txt

sort -u $TMP_DIR/all_cn.txt | sed -r 's#(.+)#ip-cidr,\1, DIRECT#g' > freesurfing.ip.1

rm -rf $TMP_DIR

diffcount=`git diff freesurfing.ip.1 freesurfing.ip | wc -l`
if [ $diffcount != 0 ]; then
   echo "Something changed."
   mv freesurfing.ip.1 freesurfing.ip
   git add freesurfing.ip
   git commit -m "update`date '+%Y%m%d%H%M'`"
   git pull && git push
else
   echo "Nothing changed, exit."
   rm freesurfing.ip.1
fi


