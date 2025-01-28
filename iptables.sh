#!/bin/bash 

#FIREWALL RESTRITIVO 
iptables -P INPUT DROP 
iptables -P OUTPUT DROP 
iptables -P FORWARD DROP 

#LIMPANDO CHAINS E TABELA NAT 
iptables -F 
iptables -t nat -F 

#REALIZANDO FILTRO BASEADO EM STATUS DE CONEXÃO 
iptables -A INPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT 
iptables -A FORWARD -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT 

#LIBERANDO LO 
iptables -A INPUT -i lo -j ACCEPT 
iptables -A OUTPUT -o lo -j ACCEPT 

#LIBERANDO SSH 
iptables -A INPUT -p tcp --dport 22 -j ACCEPT 
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT 
 
#LIBERANDO ICMP PARA O FIREWALL SOMENTE 
iptables -A INPUT -p icmp -j ACCEPT 
iptables -A OUTPUT -p icmp -j ACCEPT 

#ACESSO SSH INTERNO 
iptables -A INPUT -s 192.27.30.0/24 -p tcp --dport 22 -j ACCEPT 
iptables -A OUTPUT -d 192.27.30.0/24 -p tcp --sport 22 -j ACCEPT 
iptables -A INPUT -s 192.27.10.1 -p tcp --dport 22 -j ACCEPT 
iptables -A OUTPUT -d 192.27.10.1 -p tcp --sport 22 -j ACCEPT 
iptables -A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT 
iptables -A OUTPUT -o eth1 -p tcp --sport 22 -j ACCEPT 

#LIBERANDO REPOSITORIO APT - MODO 2 (APENAS PARA O FIREWALL) 
iptables -A INPUT -p udp --sport 53 -j ACCEPT #liberando DNS ao firewall 
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT #liberando DNS ao firewall 
iptables -A INPUT -s ftp.br.debian.org -p tcp --sport 80 -j ACCEPT #liberado APT ao firewall 
iptables -A OUTPUT -d ftp.br.debian.org -p tcp --dport 80 -j ACCEPT #liberado APT ao firewall 

#LIBERAR REPOSITORIO PARA DMZ INTERNA APENAS 
iptables -A FORWARD -p udp --sport 53 -j ACCEPT #LIBERANDO DNS PARA A REDE LOCAL 
iptables -A FORWARD -p udp --dport 53 -j ACCEPT #LIBERANDO DNS PARA A REDE LOCAL 
iptables -A FORWARD -i vlan30 -d ftp.br.debian.org -p tcp --dport 80 -j ACCEPT 
iptables -A FORWARD -s ftp.br.debian.org -p tcp --sport 80 -o vlan30  -j ACCEPT 

#LIBERANDO ICMP ENTRE SUB-REDES 
iptables -A FORWARD -p tcp --sport 22 -j ACCEPT 
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT 

#LIBERAR ACESSO ENTRE CLIENTES 
iptables -A FORWARD -i vlan10 -o vlan20 -j ACCEPT 

#REJEITAR ICMP DA REDE INTERNA - CLIENTE XP - PARA A DMZ EXTERNA 
iptables -A FORWARD -o eth1 -p icmp -s 192.27.20.1 -j LOG --log-prefix "Teste Ping " 
iptables -A FORWARD -i eth1 -p icmp -d 192.27.20.1 -j LOG --log-prefix "Teste Ping " 
iptables -A FORWARD -o eth1 -p icmp -s 192.27.20.1 -j REJECT 
iptables -A FORWARD -i eth1 -p icmp -d 192.27.20.1 -j REJECT 

#LIBERAR ICMP ENTRE HOSTS DO CENÁRIO 
iptables -A FORWARD -i eth0 -p icmp -j DROP 
iptables -A FORWARD -o eth0 -p icmp -j DROP 
iptables -A FORWARD -i vlan10 -p icmp -j ACCEPT 
iptables -A FORWARD -i vlan20 -p icmp -j ACCEPT 
iptables -A FORWARD -i vlan30 -p icmp -j ACCEPT 
iptables -A FORWARD -i eth1 -p icmp -j ACCEPT 

# LIBERAR A INTERNET (NAVEGADOR) ; EXCETO CLIENTE DA VLAN20 
iptables -A FORWARD ! -i vlan20 -p tcp --dport 443 -j ACCEPT 
iptables -A FORWARD ! -i vlan20 -p tcp --dport 80 -j ACCEPT 

#LIBERANDO SSH PORTA 2222 
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT 
iptables -A OUTPUT -p tcp --dport 2222 -j ACCEPT 
iptables -A FORWARD -p tcp --dport 2222 -j ACCEPT 

#################### TRABALHANDO COM A TABELA NAT ####################### 
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE #(habilita comunicação com a internet) 
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 192.27.30.2:80 
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to 192.27.30.1:80 
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 3389 -j DNAT --to 172.20.27.1:3389 

#Liberando rdp para winservices 
iptables -A FORWARD -i eth0 -d 172.20.27.1 -p tcp --dport 3389 -j ACCEPT 
  
#Liberando acessos SSH 
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2222 -j DNAT --to 192.27.30.2:2222 #cacdnsweb 
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2221 -j DNAT --to 192.27.30.1:22 #nagmail 
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2220  -j DNAT --to 192.27.30.254:22 #fw
