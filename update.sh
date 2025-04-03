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
echo "Updating China domain"
wget https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf
awk -F/ '{ printf "DOMAIN-SUFFIX,%s, DIRECT\n",$2}' accelerated-domains.china.conf > freesurfing.chn.domain

echo "Updating CN"

cat $TMP_DIR/ip.* | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" int(32-log($5)/log(2))}' | cat >$TMP_DIR/all_cn.txt
sort -uV $TMP_DIR/all_cn.txt | sed -r 's#(.+)#ip-cidr,\1, DIRECT#g' >freesurfing.chn.qx
sort -uV $TMP_DIR/all_cn.txt | sed -r 's#(.+)#IP-CIDR,\1, DIRECT#g' >freesurfing.chn.surge
echo "freesurfing.chn"
sort -uV $TMP_DIR/all_cn.txt | sed -r 's#(.+)#\1#g' >freesurfing.chn

echo "Updating asn"
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"   \
   -H "Accept: text/html"      https://bgp.he.net/country/CN \
   | grep -oE "/(AS[0-9]+).*title=\"\1.*\1" \
   | sed  "s/\/AS\([0-9][0-9]*\)\".*-\(.*\)\".*/IP-ASN,\1 \/\/\2/g" \
   > asn.chn

rm -rf $TMP_DIR

echo "Updating gfwlist"
curl https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt \
| base64 -d \
| grep -Ev "^[!@ /\[]" \
| grep -Eo "[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)+" \
| sort -u \
| sed "s/^/DOMAIN-SUFFIX, /" \
| sed "s/$/, PROXY/" > freesurfing.gfw


diffcount=$(git diff freesurfing* asn.chn  | wc -l)
if [ $diffcount != 0 ]; then
   echo "Something changed."
     git add freesurfing* asn.chn
     git commit -m "update`date '+%Y%m%d%H%M'`"
   if [[ $1 != "--nopush" && $1 != "--debug" ]]; then
      git pull && git push
   fi
else
   echo "Nothing changed, exit."
fi
