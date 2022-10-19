# FOG Project (Linux alternativ til WDS)

## VM 1 (Firewall)

Jeg starter med at installere en virtuel firewall. Vælger at bruge Pfsense fordi den har mange features.

Inden jeg tænder VM - aktivere jeg 2 NIC's en til yddersiden og en til indersiden.

![](https://i.imgur.com/bDf6WmV.png)

Der bliver sat DHCP rolle på indersiden. (em1)


## VM 2 (FOG Project Server)

Jeg vælger også at installere en Ubuntu Server 20.4 og tildele den en statisk IP.

```
192.168.1.10
```

Denne VM skal bruges til installation af FOG Project.


Starter altid med at opdatere

``` bash
sudo apt update && sudo apt upgrade -y
```


For at kunne SSH ind på maskinen helt ude fra kører jeg mit script.

``` bash
sudo apt install git -y
```

``` bash
git clone https://github.com/patinas/ZeroTierAuto
```

``` bash
sudo chmod +x ~/ZeroTierAuto/*
```

``` bash
cd ZeroTierAuto
```

``` bash
./script.sh
```

For at tjekke IP, VM er blevet tildelt.
```
ip a
```

![](https://i.imgur.com/VbZy1hf.png)

IP som kan bruges til SSH forbindelse ude fra er 192.168.192.115

**Man skal også være forbundet til ZeroTier netværk fra maskinen man vil forbinde fra.**

### Installation af FOG Project på Ubuntu Server 20.4

```
sudo -i
```
```
cd /opt
```

```
wget https://github.com/FOGProject/fogproject/archive/1.5.9.tar.gz
```

```
tar -xzvf 1.5.9.tar.gz
```

```
cd fogproject-1.5.9/bin
```

```
./installfog.sh
```

Nedenstående indstillinger bliver benyttet. Vælger at bruge selve FOG-Serveren son DHCP Server.

```
 * Here are the settings FOG will use:
 * Base Linux: Debian
 * Detected Linux Distribution: Ubuntu
 * Interface: enp0s3
 * Server IP Address: 192.168.1.10
 * Server Subnet Mask: 255.255.255.0
 * Server Hostname: us01
 * Installation Type: Normal Server
 * Internationalization: 1
 * Image Storage Location: /images
 * Using FOG DHCP: No
 * DHCP will NOT be setup but you must setup your
 | current DHCP server to use FOG for PXE services.

 * On a Linux DHCP server you must set: next-server and filename

 * On a Windows DHCP server you must set options 066 and 067

 * Option 066/next-server is the IP of the FOG Server: (e.g. 192.168.1.10)
 * Option 067/filename is the bootfile: (e.g. undionly.kpxe)
```

Efter installation logger jeg ind i management GUI med nedenstående informationer.

![](https://i.imgur.com/L7Mlsot.png)


Nu skal man gå ind på sin firewall og linke FOG serveren og DHCP Serveren sammen - I dette tilfælde, aggerer min Pfsense firewall som DHCP Server.

![](https://i.imgur.com/BkJiwVT.png)

Derefter genstarter jeg DHCP service.

![](https://i.imgur.com/R0XTaXG.png)


Overstående kan man finde Services > DHCP Server > Network booting (Dette gælder, dog kun Pfsense Firewall)


## Klargøring af Windows image.

Installerer en Windows 10 VM og konfigurere den, som den skal være hver gang den bliver deployet. Husker at sætte interface til det det interne LAN interface, så FOG Serveren kan finde VM'en.

![](https://i.imgur.com/kwszqEt.png)


## Overførelse af image til deployment serveren.

Efter installation, og Windows er konfigureret som jeg vil have det, slukker jeg VM, og indstiller maskinen, at den skal boote ved hjælp af netværk.

![](https://i.imgur.com/ueXLGRX.png)


Registrerer maskinen, efter boot fra netværk.

![](https://i.imgur.com/yECWPbW.png)


Så bruger jeg FOG dashboard til oprettelse af et image.

![](https://i.imgur.com/zic3s4a.gif)

![](https://i.imgur.com/7JlCVkA.png)


Derefter tilføjer jeg host maskinen.

![](https://i.imgur.com/uc157xF.gif)


Derefter sætter jeg opgaven i gang ved næste boot af maskinen.

![](https://i.imgur.com/jBhZCsH.gif)


Jeg husker at slukke maskinen helt, så tænder jeg den igen og processen går i gang automatisk.

![](https://i.imgur.com/8P297uD.gif)


Opretter og booter fra en blank VM til test af deployment. Jeg husker at sætte netværks boot til. Vælger registrering af VM til fog serveren først.

![](https://i.imgur.com/32ZbCu5.png)

Vælger hvad min maskine skal hedde.

![](https://i.imgur.com/3YwGAdR.png)


I dette tilfælde vælger jeg at sige nej som understående screendump, da FOG har mange ekstra features som kunne konfigures, men vælger en simplificeret udgave.

![](https://i.imgur.com/fGH5BJx.png)


Genstarter maskinen (VM) og vælger Deploy Image.

![](https://i.imgur.com/JcRBHrV.png)


Sætter mit FOG username og password ind.

![](https://i.imgur.com/AXkXzky.png)


Vælger Win10 image som blev oprettet tidligere.

![](https://i.imgur.com/qJ54j84.png)


Så går deployment processen i gang.

![](https://i.imgur.com/pa7nOmv.gif)




