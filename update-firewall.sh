ALLOWED_HOSTS_URL="https://sshfs.net/allowed_hosts.txt"
ALLOWED_IPS_URL="https://sshfs.net/allowed_ips.txt"

echo
echo "Downloading Allow Files..."
echo

wget -nv $ALLOWED_HOSTS_URL -O allowed.hosts
wget -nv $ALLOWED_IPS_URL -O allowed.ips

echo
echo "Resolving Allowed Hosts..."
echo

readarray domains < allowed.hosts
for i in ${domains[@]}; do
        IPv4=`dig $i A +short`
        echo "$IPv4" >> ip.tmp
         IPv6=`dig $i AAAA +short`
        echo "$i"
        echo "IPv4: $IPv4"
        echo "IPv6: $IPv6"
        echo "----------"
        echo "$IPv6" >> ip.tmp
done

echo
echo "Adding Allowed IP Addresses..."
echo
cat allowed.ips
cat allowed.ips >> ip.tmp
echo
echo
echo "Updating Firewall Rules..."
echo

readarray a < ip.tmp
for i in ${a[@]}; do
        ufw allow from $i
done
rm ip.tmp

echo
echo
ufw status numbered
echo
echo "Done!"
echo
exit
