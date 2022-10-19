# CyberSikkerhed - Hacking og sikkerhed

## Forudsætninger

- Kali Linux
- Et lukket LAN man kan teste på.
- Ubuntu Server 22.04 (VM)
- Docker og docker-compose
- Portainer (optionelt)


### NTOPNG

NTOPNG er et netværks monitoring værktøj. Vælger selv at køre det i docker.
```
sudo apt update
```

Root bruger
```
sudo -i
```


Bruger mit eget script til installation af docker og portainer. Portainer er ikke et "must" men gør det lidt nemmere.
```
git clone https://github.com/patinas/scripts
```

```
cd scripts
```

```
cd docker
```

```
sh portainer.sh
```

Ubuntu serverens lokal IP og port 9000 for at tilgå "portainer"
http://192.168.1.25:9000/

```
cd
```


```
mkdir ntopng
```


```
cd ntopng
```

Tjek af NIC navn - skal bruges senere. I mit tilfælde er det "ens160"
```
ip a
```


```
sudo nano docker-compose.yml
```


```
version: '3'

services:

  ntopng:
    image: vimagick/ntopng
    command: --community -d /var/lib/ntopng -i <your NIC name here> -r 127.0.0.1:6379@0 -w 0.0.0.0:3410
    volumes:
      - ./data/ntopng:/var/lib/ntopng
    network_mode: host
    restart: unless-stopped

  redis:
    image: redis:alpine
    command: --save 900 1
    ports:
      - "6379:6379"
    volumes:
      - ./data/redis:/data
    restart: unless-stopped
```

```
mkdir data
```


```
docker-compose up -d
```
Giv det cirka 1 minut, besøg derefter maskinens IP (server IP) på en maskine på LAN'et og det portnummer, der er angivet i filen docker-compose.yml (http://192.168.1.25:3410/), og brug standardloginoplysningerne understående for at logge ind.


username: admin
password: admin



### Network Intrusion Detection System (NIDS)

#### SNORT

Snort er det førende Open Source Intrusion Prevention System (IPS) i verden. Snort IPS bruger en række regler, der hjælper med at definere ondsindet netværk


Følgende tester jeg på Ubuntu server. 


Opdatering af repositories.
```
sudo apt update
```

Installation af program.
```
sudo apt install snort
```


Excevering af monitoring værktøj.
```
sudo snort -A console -q -u snort -g snort -c /etc/snort/snort.conf -i ens160
```

Understående kan man se at når jeg prøver at bruge nmap fra en Kali Linux maskine, opdager SNORT det.
![](https://i.imgur.com/IaPVoqF.gif)


#### Prometheus og Grafana

Prometheus er et open source overvågningssystem, som Grafana leverer frontend til. 



Opretter en mappe og i den mappe en opretter jeg en YML fil som er konfigurationen for Prometheus.
```
sudo mkdir /etc/prometheus
sudo micro /etc/prometheus/prometheus.yml
```

Indhold af config fil, understående.
```
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  # external_labels:
  #  monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'
    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

  # Example job for node_exporter
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']

  # Example job for cadvisor
   - job_name: 'cadvisor'
     static_configs:
      - targets: ['cadvisor:8080']
```



docker-compose.yml 
```

version: '3'

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - /etc/prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    restart: unless-stopped
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"

  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    restart: unless-stopped
    
    
  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node_exporter
    command:
      - '--path.rootfs=/host'
    pid: host
    restart: unless-stopped
    volumes:
      - '/:/host:ro,rslave'
      
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    # ports:
    #   - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    devices:
      - /dev/kmsg
    restart: unless-stopped
```


Bruger Portainer til deployment af stack.
![](https://i.imgur.com/lPqCtej.gif)


**Mere info om opsætning af Grafana**
https://youtu.be/9TJx7QTrTyo


**Resultat**
![](https://i.imgur.com/w2DXaWI.gif)




### Hacking med Kali Linux

#### Skanning af vulnerabilities på Linux

Nmap ("Netværksmapper") er et gratis og open source-værktøj til netværksopdagelse og sikkerhedsrevision.

Brug af root bruger.
```
sudo -i
```

Scan af public IP for vulnerabilities.
```
nmap --script vuln [PUBLIC IP]
```

Scan af internt netværk for forbundet hosts og deres OS'er (Operating Systems)
```
nmap -sT -O 192.168.1.0/24
```


#### MITM (Man In The Middle) Attack - Rogue DHCP Server

Et sted at udføre man-in-the-middle angreb er for eksempel med DHCP-tjenesten (Dynamic Host Configuration Protocol), som er ansvarlig for at allokere lokale IP-adresser.

**Kali Linux (Attacker)**

Med følgende værktøj kan meget nemt lave en rogue DHCP Server.

*Ettercap*
![](https://i.imgur.com/mHTfmoS.png)


**Windows 10 (Client)**

Enten en genstart af maskinen eller nedenstående, for at få IP fra rogue DHCP server (vores Kali maskine)

```
ipconfig /release
ipconfig /renew
```



#### Phising Attack

Kloning af website med understående command.
```
setoolkit
```

![](https://i.imgur.com/7p8eisc.gif)


Understående kan man se at hvis man besøger http://192.168.1.101/ får man en klon af den originale side https://theitguide.xyz/

Man kan også se i realtid hvor traffiken kommer fra med IP og andre oplysninger på højre side.
![](https://i.imgur.com/v6jLQti.gif)


#### Rogue DNS

Overstående attacks kan kombineres og det medføre at når brugeren besøger "test.local" kommer ind på vores hjemmelavede side. 

Starter en webserver på Kali.
```
systemctl start apache2
```

Konfigurere Kali som DNS server.
```
dnschef --fakeip=192.168.1.101 --fakedomains=test.local --interface=192.168.1.101
```

Overstånde bruger jeg i forbindelse med Ettercap, hvor jeg specifiserer IP af Kali som DNS server.

Resultat (Dette kan være en clone af en side)
![](https://i.imgur.com/tAUSfCk.png)




##### DHCP Sikkerhed

Overstående attacks kan forhindres med best sikkerheds practices, hvor man ikke lader netværksudstyr have standardindstillinger men laver en custom konfigurering med blandt andet DHCP snooping slået til. DHCP snooping er en sikkerhedsfunktion som kan bruges primært på Cisco udstyr, som gør det sværere at lave et MITM attack med en rogue DHCP server.


#### Routersploit til IoT devices

"Routersploit" finder vulnarabilites på IoT devices som f.eks. routere. I dette eksempel finder jeg 2 exploitable vulnarabilities på en hjemme router som er på mit interne netværk.

Som root bruger
```
git clone https://github.com/Exploit-install/routersploit.git
```

Tilgår mappen
```
cd routersploit
```

Installere forudsætninger
```
pip install -r requirements.txt
```


Kører Routersploit
```
python3 rsf.py
```

Tilgår target scanner
```
use scanners/autopwn
```

Sætter target som, er i dette tilfælde er min D-Link router.
```
set target 192.168.1.1
```

Kører scanningen
```
run
```
![](https://i.imgur.com/LpAH8BA.gif)



![](https://i.imgur.com/FK35EMj.png)

Som man kan se overstående blev der fundet 2 vulnerabilities som man derefter kan læse om online finde commands som kan bruges til det specifikke exploit.

Måden at give IoT devices mere sikkerhed er at sætte på et seperat VLAN og grannulere access til porte. Som hjemmebruger burde man huske at lave om på default kode til tilgang af router som f.eks bruger: admin, password: admin. Man burde også opdatere firmware på router hver gang der kommer en ny opdatering, da dette øger sikkerheden. Overstående vulnarabilities kunne måske undgås hvis routeren var opdateret med nyeste firmware.


### Nessus

Nessus er en netværkssikkerhedsscanner. Den bruger plug-ins, til at håndtere sårbarhedskontrollen.

```
docker run --name "nessus" -d -p 8834:8834  -e ACTIVATION_CODE=3ZT4-YJPW-E93K-NJNN-DTZK -e USERNAME=user -e PASSWORD=root tenableofficial/nessus 
```


Efter setup i docker, vælger man et netværk/flere netværk som den skal finde hosts på.
![](https://i.imgur.com/OwAXfYE.png)


Resultat fra scan
![](https://i.imgur.com/hDaqekU.png)


Ved hjælp af Nessus finder jeg ud at min redis server til et andet program ikke bruger authentication.
![](https://i.imgur.com/vsWGkPb.png)


### Selks

Et færdigt Suricata-baseret IDS/IPS/NSM-økosystem i et docker container miljø.

![](https://i.imgur.com/peaWaM2.png)



Installation
```
git clone https://github.com/StamusNetworks/SELKS.git
cd SELKS/docker/
./easy-setup.sh
docker-compose up -d
```

Besøger siden på https://192.168.1.99/ som er en Ubuntu Server 22.4, hvor container kører.

**Default OS user:**

user: selks-user
password: selks-user


For at teste om IDS virker.
```
curl http://testmynids.org/uid/index.html
```

Resultat under "Suricata Threat Hunting" > "Alerts"
![](https://i.imgur.com/yM5ukvn.png)


### CrowdSec

CrowdSec er et gratis community driven threatdetektionsværktøj.

Logge ind som root.
```
sudo -i
```

Installation af CrowdSec
```
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
```

```
apt install crowdsec
```

Bruger web console til monitoring og alerts.
https://app.crowdsec.net/
![](https://i.imgur.com/PJLdsrn.png)


