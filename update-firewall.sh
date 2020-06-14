#!/bin/bash

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
        ufw allow from $i
done
rm ip.tmp
echo
echo "Reloading Firewall..."
ufw reload
echo
ufw status numbered
echo
echo "Success!"
echo
exit
