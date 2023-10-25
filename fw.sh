#!/bin/sh

################### 
# Define variables
###################

## Public bridge holds physical interface (public IP, output gateway)
Public_Bridge="vmbr2"

## WAN bridge ( holds WAN_Network )
WAN_Bridge="vmbr1"

## LAN bridge ( holds Lan Network )
LAN_Bridge="vmbr0"

## Network between hypervisor and firewall
WAN_Network="192.168.100.0/24"

## Network between firewall and VMs
LAN_Network="10.0.1.0/24"

## VPN network
VPN_Network="10.8.0.0/24"

## IPV4 public IP of the physical interface 
Public_IP="x.x.x.x"

## Hypervisor IP inside the WAN network
Hypervisor_Wan_IP="192.168.100.1"

## Hypervisor IP inside the LAN network
Hypervisor_LAN_IP="10.0.1.1"

## Firewall IP inside the WAN network
Firewall_WAN_IP="192.168.100.2"

## SSH Port
SSH_Port="22"

################### 
# Cleanup
###################

# Delete all the rules of every chains ( table filter )
# iptables -F
iptables --flush

# Delete all the rules of every chains ( table nat )
# iptables -t nat -F
iptables --table nat --flush

# Delete all the rules of every chains ( table mangle )
#iptables -t mangle -F
iptables --table mangle --flush

# Delete all user-defined chains 
#iptables -X
iptables --delete-chain

# Cleanup IPv6 policies
ip6tables --policy INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP

# Cleanup IPv4 policies
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

################### 
# Chains
###################

# Create chains
iptables --new-chain TCP
iptables -N UDP

# Define rules on capturing UDP and TCP connexions
iptables --append INPUT --protocol udp --match conntrack --ctstate NEW --jump UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP

################### 
# Global rules
###################

# Allow localhost
#iptables -A INPUT -i lo -j ACCEPT
#iptables -A OUTPUT -o lo -j ACCEPT
iptables --append INPUT --in-interface lo --jump ACCEPT
iptables --append OUTPUT --out-interface lo --jump ACCEPT

# Don't break current or active connections
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Allow ICMP
iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT

######################## 
# Incoming traffic rules
########################

# Allow SSH connections
iptables -A TCP -i $Public_Bridge -d $Public_IP -p tcp --dport $SSH_Port -j ACCEPT

# Allow Proxmox WebUI
iptables -A TCP -i $Public_Bridge -d $Public_IP -p tcp --dport 8006 -j ACCEPT

######################## 
# Outcoming traffic rules
########################

# Allow ping out
iptables -A OUTPUT -p icmp -j ACCEPT

# Allow HTTPS/HTTP
iptables -A OUTPUT -o $Public_Bridge -s $Public_IP -p tcp --dport 80 -j ACCEPT
# ip6tables -A OUTPUT -o $Public_Bridge -s $Public_IP -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -o $Public_Bridge -s $Public_IP -p tcp --dport 443 -j ACCEPT
# ip6tables -A OUTPUT -o $Public_Bridge -s $Public_IP -p tcp --dport 443 -j ACCEPT

# Allow DNS
iptables -A OUTPUT -o $Public_Bridge -s $Public_IP -p udp --dport 53 -j ACCEPT

# Allow SSH
iptables -A OUTPUT -o $Public_Bridge -s $Public_IP -p tcp --sport $SSH_Port -j ACCEPT

# Allow Proxmox WebUI
iptables -A OUTPUT -o $Public_Bridge -s $Public_IP -p tcp --sport 8006 -j ACCEPT

# Allow to access VMs from Hypervisor
iptables -A OUTPUT -o $WAN_Bridge -s $Hypervisor_Wan_IP -p tcp -j ACCEPT

###########################
# Forwarding traffic rules
###########################

# Send all TCP traffic from Public IP to WAN network, except for the SSH port and Proxmox WebUI
iptables -A PREROUTING -t nat -i $Public_Bridge -p tcp --match multiport ! --dports $SSH_Port,8006 -j DNAT --to $Firewall_WAN_IP

# Send all UDP traffic from Public IP to WAN network
iptables -A PREROUTING -t nat -i $Public_Bridge -p udp -j DNAT --to $Firewall_WAN_IP

# Allow request forwarding to firewall through WAN network
iptables -A FORWARD -i $Public_Bridge -d $Firewall_WAN_IP -o $WAN_Bridge -p tcp -j ACCEPT
iptables -A FORWARD -i $Public_Bridge -d $Firewall_WAN_IP -o $WAN_Bridge -p udp -j ACCEPT

# Allow request from LAN
iptables -A FORWARD -i $WAN_Bridge -s $WAN_Network -j ACCEPT

# Allow WAN network to use public IP gateway to go out
iptables -t nat -A POSTROUTING -s $WAN_Network -o $Public_Bridge -j MASQUERADE
