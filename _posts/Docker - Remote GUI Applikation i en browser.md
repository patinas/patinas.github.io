# Docker - Remote GUI Applikation i en browser

## Setup
- Setup of installation af ESXi og management maskine.
- Upload af ISO'er til ESXi.
- Installation af Ubuntu Server.

### Setup til management med SSH med hjemmelavet script. (ZeroTier VPN)

```
sudo -i
git clone https://github.com/patinas/scripts
sh /root/scripts/post_install_minimal.sh
```

**Resultat**
Kan nu bruge ZeroTier netværk til management af server med SSH med statisk IP.
![](https://i.imgur.com/SQcGaTH.png)

Management Maskine (Et virtuelt NIC bliver tilføjet, som får en statisk IP fra ZeroTier netværk i skyen)
![](https://i.imgur.com/qdaVMW4.png)


## Installation af Portainer og Docker ved hjælp af hjemmelavet script.

Dette script installere docker engine og portainer som management GUI.

```
sudo -i
git clone https://github.com/patinas/scripts
sh /root/scripts/docker/portainer.sh
```

![](https://i.imgur.com/WBjPpDQ.png)


## Test med applikation: Packet Tracer

Applikation skal hentes først som *.deb package fra Netacad og **skal** være i mappen, nedenstående command bliver kørt fra. 

![](https://i.imgur.com/6RdB64b.png)


```
docker run -it -v $(pwd):/src -p 10000:8080 ubuntu
```

Så er jeg inde på container, hvor jeg kan installere Packet Tracer og "xpra" som gør at man se GUI på en applikation i et browser vindue.

```
apt update
apt install sudo
apt install -y curl gnupg wget apt-transport-https software-properties-common
sudo apt-get update
sudo apt-get install -y libqt5webkit5 libqt5multimedia5 libqt5xml5 libqt5script5 libqt5scripttools5
wget http://mirrors.kernel.org/ubuntu/pool/main/i/icu/libicu52_52.1-3ubuntu0.8_amd64.deb
wget http://ftp.debian.org/debian/pool/main/libp/libpng/libpng12-0_1.2.50-2+deb8u3_amd64.deb
sudo dpkg -i libicu52_52.1-3ubuntu0.8_amd64.deb
sudo dpkg -i libpng12-0_1.2.50-2+deb8u3_amd64.deb
dpkg -i CiscoPacketTracer_820_Ubuntu_64bit.deb
apt install -f
dpkg -i CiscoPacketTracer_820_Ubuntu_64bit.deb
apt install xpra -y
```

Tilgår portainer
![](https://i.imgur.com/eseAkb4.png)

![](https://i.imgur.com/D9TUVEP.png)

Kører nedenstående command for at starte xpra client.
![](https://i.imgur.com/g9l7VlX.png)


```
xpra start --start=packettracer --bind-tcp=0.0.0.0:8080 --html=on
```


## Resultat

![](https://i.imgur.com/SN9pG2F.png)

