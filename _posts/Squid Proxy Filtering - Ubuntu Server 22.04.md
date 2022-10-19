# Squid Proxy Filtering - Ubuntu Server 22.04


## Metode 1 - Squid (standalone)

```
sudo -i
git clone https://github.com/patinas/scripts
cd scripts
sh squid.sh
```


Indhold i "squid.sh" script.
```
#!/bin/sh

# Installation af Squid.
apt update
apt install squid -y

# Backup af original squid fil og sletning af kommenterede linjer i fil.
cp /etc/squid/squid.conf /etc/squid/squid.conf.old
grep -o '^[^#]*' squid.conf.old > squid.conf

# Indhold i modificeret squid configurations fil.
tee /etc/squid/squid.conf <<EOF
acl localnet src 10.0.0.0/8	
acl localnet src 172.16.0.0/12	
acl localnet src 192.168.0.0/16	
acl localnet src fc00::/7       
acl localnet src fe80::/10      
acl SSL_ports port 443
acl Safe_ports port 80		
acl Safe_ports port 21		
acl Safe_ports port 443		
acl Safe_ports port 70		
acl Safe_ports port 210		
acl Safe_ports port 1025-65535	
acl Safe_ports port 280		
acl Safe_ports port 488		
acl Safe_ports port 591		
acl Safe_ports port 777		
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access deny to_localhost
http_access allow localhost

acl domains dstdomain "/etc/squid/domains.acl"
http_access deny localnet domains
acl keyword_block url_regex "/etc/squid/keyword_block.acl"
http_access deny localnet keyword_block
http_access allow localnet

http_access deny all
http_port 3128
cache_dir ufs /var/spool/squid 100 16 256
coredump_dir /var/spool/squid
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
refresh_pattern .		0	20%	4320
EOF

# Blokering af domains - fil.
tee /etc/squid/domains.txt <<EOF
.facebook.com
.youtube.com
EOF

# Blokering af keywords - fil.
tee /etc/squid/keyword_block.txt <<EOF
facebook
youtube
EOF

# Genstart af Squid.
systemctl restart squid

# Live monitoring af logs
watch tail /var/log/squid/access.log
```

Bruger Firefox som browser til test, hvor jeg indsætter IP til proxy server.
![](https://i.imgur.com/nsYAdOR.png)


## Metode 2 - SquidGuard

Opretter en script fil som indeholder hele installation og konfiguration af Squid Proxy. Der kan laves ændringer i "domains" fil efter behov, hvilke sider der skal blokeres. Netværk ændres også efter behov i squid config fil - Bruger netværk "192.168.1.0/24" som eksempel.

```
sudo -i
nano script.sh
```

Script skal indeholde nedenstående. Vigtige linjer har kommentarer igennem script.

```
#!/bin/sh

# Opdatering og installation af Squid.
apt update && apt upgrade -y
apt install squid -y

cd /etc/squid

# Backup af original squid config fil.
cp /etc/squid/squid.conf /etc/squid/squid.conf.old

# Sletning af kommenterede linjer i original fil.
grep -o '^[^#]*' squid.conf.old > squid.conf

# Sletning "http_access deny all" til tilføjelse til sidst i filen senere.
grep -v "http_access deny all" squid.conf > tmpfile && mv tmpfile squid.conf



# Tilføjelse af argumenter til squid config. ACL til tilladt netværk. I mit tilfælde er det - 192.168.1.0/24
tee -a /etc/squid/squid.conf <<EOF
acl localnet src 192.168.1.0/24
http_access allow localnet
EOF

# Installation af SquidGuard, som er løsning til blokering af sider.
apt install squidguard -y
cd /var/lib/squidguard/db

# Oprettelse af "domains" fil, hvor blacklist bliver sat ind.
tee /var/lib/squidguard/db/domains <<EOF
facebook.com
youtube.com
EOF

# Oprettelse af "expressions" fil, hvor blacklist keywords bliver sat ind.
# tee /var/lib/squidguard/db/expressions <<EOF
# facebook|youtube|torrents|voldermort
# EOF


cd /etc/squidguard

# Backup af original squidguard config fil.
cp squidGuard.conf squidGuard.conf.old


# Modificering af original SquidGuard fil.
tee /etc/squidguard/squidGuard.conf <<EOF
#
# CONFIG FILE FOR SQUIDGUARD
#
# Caution: do NOT use comments inside { }
#

dbhome /var/lib/squidguard/db
logdir /var/log/squidguard

#
# TIME RULES:
# abbrev for weekdays: 
# s = sun, m = mon, t =tue, w = wed, h = thu, f = fri, a = sat

time workhours {
        weekly mtwhf 08:00 - 16:30
        date *-*-01  08:00 - 16:30
}

#
# SOURCE ADDRESSES:
#

src admin {
        ip              1.2.3.4  1.2.3.5
        user            root foo bar
        within          workhours
}

src foo-clients {
        ip              172.16.2.32-172.16.2.100 172.16.2.100 172.16.2.200
}

src bar-clients {
        ip              172.16.4.0/26
}

#
# DESTINATION CLASSES:
#
# [see also in file dest-snippet.txt]

dest good {
}

dest local {
}

dest porn {
}

#dest adult {
#       domainlist      BL/adult/domains
#       urllist         BL/adult/urls
#       expressionlist  BL/adult/expressions
#       redirect http://admin.foo.bar.de/cgi-bin/block
#}

dest blacklist {
        domainlist      domains
}

#
# ACL RULES:
#

acl {
        admin {
                pass     any
        }

        foo-clients within workhours {
#               pass     good !in-addr !porn any
        } else {
                pass any
        }

        bar-clients {
                pass    local none
        }

        default {
                pass     !blacklist any
                redirect https://sites.google.com/view/blockedsquid/home
        }
}
EOF



squidGuard -C all
cd /var/lib/squidguard/

# Så Squid har en forbindelse til SquidGuard.
chown -R proxy:proxy /var/lib/squidguard/db
chown -R proxy:proxy /var/log/squidguard
chmod -R 755 /var/lib/squidguard/db/



# Tilføjelse af ekstra argumenter til squid config.
tee -a /etc/squid/squid.conf <<EOF
url_rewrite_program /usr/bin/squidGuard
http_access deny all
EOF



systemctl restart squid


# Til monitoring af hvad der sker når proxy bliver brugt.
tail -f /var/log/squid/access.log
```

Kør script.

```
sh script.sh
```


Resultat
![](https://i.imgur.com/OHEpoau.gif)



## Metode 3 - DNS Blocking med PiHole

Starter forfra med en nyinstalleret Ubuntu Server 22.04.

```
sudo -i
git clone https://github.com/patinas/scripts
cd scripts
sh block.sh
```

Indhold i script vises nedenstående.

```
#!/bin/sh

apt update

# Stopper den interne DNS service.
systemctl stop systemd-resolved.service

# Sletter loopback fra resolf.conf.
grep -v "nameserver 127.0.0.53" /etc/resolv.conf > tmpfile && mv tmpfile /etc/resolv.conf

# Tilføjer Google's DNS.
tee -a /etc/resolv.conf <<EOF
nameserver 8.8.8.8
EOF

apt update

# Installere Docker og Git.
apt install docker.io -y
apt install git -y

# Henter et andet script som automatisere tilføjelse af pihole container.
git clone https://github.com/patinas/pihole
cd pihole
chmod u+x pihole.sh
./pihole.sh

# Tilgår container og bliver promptet til oprettelse af eget password.
docker exec -it pihole bash
```

Derefter kører jeg følgende command til ændring af password.
```
pihole -a -p
```

Ændrer klientens DNS server til Ubuntu serveren's IP.
![](https://i.imgur.com/x0S6U2r.png)
*Kan også gøres på router.*


For at tilgå WEB interface:
**http://IP_ADDRESSE_PÅ_SERVER/admin/**


Bruger facebook.com som eksempel på domæne der skal blokeres.
![](https://i.imgur.com/gjyI9AQ.png)


**Resultat**
![](https://i.imgur.com/BwVkHIP.png)


                                
                                


