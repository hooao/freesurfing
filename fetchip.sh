#!/bin/sh

TMP_DIR=`mktemp -d /tmp/chinaip.XXXXXX`

wget -q --no-check-certificate -O $TMP_DIR/ip http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest 
cat $TMP_DIR/ip | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}'|cat >$TMP_DIR/all_cn.txt

sort -u $TMP_DIR/all_cn.txt | sed -r 's#(.+)#ip-cidr,\1, DIRECT#g' > freesurfing.ip.1

rm -rf $TMP_DIR

diff = git diff freesurfing.ip.1 freesurfing.ip | wc -l
if [ diff == 0 ]; then
   echo "Nothing changed, clean up and exit."
   rm freesurfing.ip.1
   exit 0
fi

mv freesurfing.ip.1 freesurfing.ip
git add freesurfing.ip
git commit -m "update"
git pull && git push
