#!/bin/bash
echo
echo "Removing Existing Rules..."
rm /etc/firewalld/zones/public.xml
rm /etc/firewalld/zones/public.xml.old
firewall-cmd --reload
echo
echo "Reading Domain List..."
readarray domains < domain.list
for i in ${domains[@]}; do
        IP=`dig +short $i`
        echo "$i = $IP"
        echo "$IP" >> ip.tmp

done

readarray a < ip.tmp
echo
echo "Updating Rules..."

for i in ${a[@]}; do
        firewall-cmd --zone=public --permanent --add-rich-rule='rule family="ipv4" source address='"$i/32"' accept'
done
rm ip.tmp
echo
echo "Reloading Firewall..."
firewall-cmd --reload
echo
firewall-cmd --list-all
echo
echo "Success!"
echo
exit
