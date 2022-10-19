# Containerized Deployment Server med Docker

## VM 1 (Firewall)

Jeg starter med at installere en virtuel firewall. Vælger at bruge Pfsense fordi den har mange features.

Inden jeg tænder VM - aktivere jeg 2 NIC's en til yddersiden og en til indersiden.

![](https://i.imgur.com/bDf6WmV.png)

Der bliver sat DHCP rolle på indersiden. (em1)


## VM 2 (Ubuntu Server 20.4) - Docker

Jeg vælger også at installere en Ubuntu Server 20.4 og tildele den en statisk IP.

```
192.168.1.20
```

Denne VM skal bruges til installation af Docker.


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

**Man skal også være forbundet til ZeroTier netværk fra maskinen man vil forbinde fra.**


## Installation af Docker


Update af repositories
``` bash
sudo apt update
```

Installation af docker og tilføjelse til boot af maskine
``` bash
sudo apt install docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker
```

Oprettelse af 2 mapper på Ubuntu Serveren

``` bash
sudo mkdir /netbootconfig
sudo mkdir /netbootassets
```

Tilføjelse af docker container netboot.xyz

``` bash
sudo docker run -d \
  --name=netbootxyz \
  -e MENU_VERSION=2.0.47 `# optional` \
  -p 3000:3000 `# sets webapp port` \
  -p 69:69/udp `# sets tftp port` \
  -p 8080:80 `# optional` \
  -v /netbootconfig:/config `# optional` \
  -v /netbootassets:/assets `# optional` \
  --restart unless-stopped \
  ghcr.io/netbootxyz/netbootxyz
```

Åbner WEB-GUI i en browser indenfor netværket.
http://192.168.1.20:3000/

Man skal lave en ændring i "boot.cfg" - På denne måde vil man loade assets fra den lokale server.

![](https://i.imgur.com/82EFtVC.gif)

```
set live_endpoint http://192.168.1.20:8080
```

![](https://i.imgur.com/21jDJ5I.png)


Går ind i "local assets" i WEB-GUI og henter Ubuntu 20.4 med Budgie DE (Desktop Enviroment) som eksempel. Husk at hente alle de nødvendige assets ligesom på eksemplet, hvor det er 3 der skal til.

![](https://i.imgur.com/FPDJBqG.png)

## Firewall (Router) Konfiguration

Nu skal man gå ind på sin firewall og linke Ubuntu Serveren, hvor container kører og DHCP Serveren sammen - I dette tilfælde, aggerer min Pfsense firewall som DHCP Server.

![](https://i.imgur.com/WWg2PE4.png)

Overstående kan man finde Services > DHCP Server > Network booting (Dette gælder, dog kun Pfsense Firewall)

## Test

Man skal boote fra netværket og derefter vælge "Live CDs"

![](https://i.imgur.com/oztmm9Z.png)

Så finder man Ubuntu på listen.

![](https://i.imgur.com/1PaVNIA.png)


Vælger den version man har hentet tidligere i WEB-GUI.

![](https://i.imgur.com/7uRj8D3.png)

Ubuntu Budgie live miljø nedenstående - herfra kan man vælge at installere på det lokale drev eller teste miljøet men man skal huske at intet bliver gemt efter slukning af systemet.

![](https://i.imgur.com/Ww6ovEg.png)

## Windows Deployment

``` bash
sudo apt update
```

Installation af samba på Ubuntu Serveren. På denne måde kan Windows dele filer med serveren - hvor Linux serveren aggere som fil-server. Dette er fordi man skal bruge en eksisterende Windows maskine/VM til oprettelse af de nødvendige filer.

``` bash
sudo apt install samba -y
mkdir ~/share
cd /etc/samba/
sudo mv smb.conf smb.conf.old
sudo nano smb.conf
```

``` bash
[global]
server role = standalone server
map to guest = bad user
usershare allow guests = yes
workgroup = WORKGROUP

[linuxshare]
comment = Open Linux Share
path = /home/user/share
read only = no
guest ok = yes
force user = user
force group = user
force create mode = 0755
```

Så servicen starter ved boot.

``` bash
sudo systemctl enable smbd
```

Hvis man bruger den indbyggede firewall på Ubuntu Serveren.

``` bash
sudo ufw allow Samba
```

Genstart af service efter config ændringer.

``` bash
sudo systemctl restart smbd
```

Test Samba og hvis den ikke giver fejl er konfigurationen klar.

``` bash
testparm
```

Aktivering af Windows-funktionen "SMB 1.0" på Windows-maskiner som skal tilgå share.

![](https://i.imgur.com/DPV0g79.png)

**Vigtigt**
"Enable Insecure Guest Logons" på Windows - Windows 10 Local Policy Editor (gpedit.msc)

![](https://i.imgur.com/ARQfB3J.png)


Test om det virker nedenstående. ("US02" er navnet på Ubuntu Serveren i dette eksempel.)

![](https://i.imgur.com/9Eyc9Oc.gif)

Nedenstående skal hentes og installeres på Windows maskinen. (Defaults bruges ved installationerne)

Download the Windows ADK
https://go.microsoft.com/fwlink/?linkid=2165884

Download the Windows PE add-on for the Windows ADK
https://go.microsoft.com/fwlink/?linkid=2166133


Opret en WinPE ISO (Command Prompt) - åbn værktøjet som Administrator.

![](https://i.imgur.com/Np8jazi.png)


``` 
copype amd64 C:\WinPE_amd64
```

```
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE_amd64.iso
```

Flyt Windows PE ISO indhold til container på Ubuntu Serveren /netbootassets/WinPE/x64 - Jeg gjorde det med overflyttelse til share og derefter og overflyttelse fra share mappen til /netbootassets/ (Der er nok mere streamlined måder at gøre det på, men jeg følte det var hurtigst)

``` bash
sudo mv ~/share/WinPE/ /netbootassets/
```


```
set win_base_url http://192.168.1.20:8080/WinPE
```

**Der er en mulighed for at docker skal genstartes så ændringerne træder i kraft.**


På en test maskine - visning af boot ind i WindowsPE nedenstående.

![](https://i.imgur.com/rrRduaA.gif)



Derefter forbinder man til share med Windows 10 ISO indholdet.

``` powershell
net use F: \\192.168.1.20\linuxshare\Win10 /user:192.168.1.20\user <password>
```

![](https://i.imgur.com/jShoDsS.png)


Derefter skriver man nedenstående for at starte installations-wizard.

```
F:\setup.exe
```

![](https://i.imgur.com/0FuDxmj.png)


Resultat 

![](https://i.imgur.com/afgYFlU.gif)



## Automatisering

Brug af github bruger

Alle med 2 $$ i starten og 2 $$ til sidst, skal erstattes med de korrekte værdier.

Først og fremmest skal man forke netboot.xyz-custom på Github og redigere custom.ipxe-filen. Sådan skal custom filen se ud

custom.ipxe

```
#!ipxe

goto ${menu} ||

:custom_menu
menu $$username$$ custom menu
item --gap OS:
item windows ${space} Windows
choose menu || goto custom_exit
echo ${cls}
goto ${menu} ||
goto change_menu

:change_menu
chain --autofree https://raw.githubusercontent.com/${github_user}/netboot.xyz-custom/master/${menu}.ipxe || goto error
goto custom_menu

:custom_exit
exit 0
```

Derefter laver man en "windows.ipxe" fil på sin github og tilføjer med nedenstående. Man skal huske at ændre variablerne med $$ som nævnt i starten. 

windows.ipxe

```
#!ipxe

# Microsoft Windows
# https://www.microsoft.com

set winpe_arch x64
set win_image Win10_20H2_English_x64
set win_base_url $$win_base_url$$
goto ${menu} ||

:windows
set os Microsoft Windows
clear win_version
menu ${os} 
item --gap Installers
item win_install ${space} Load ${os} Installer...
item --gap Options:
item image_set ${space} Image [ ${win_image} ]
item pe_arch_set ${space} Architecture [ ${winpe_arch} ]
item url_set ${space} Base URL [ ${win_base_url} ]
choose win_version || goto windows_exit
goto ${win_version}

:image_set
menu Image
item Win10_1909_English_x64 Win10_1909_English_x64
item Win10_20H2_English_x64 Win10_20H2_English_x64
choose win_image && goto windows

:pe_arch_set
iseq ${winpe_arch} x64 && set winpe_arch x86 || set winpe_arch x64
goto windows

:url_set
echo Set the HTTP URL of an extracted Windows ISO without the trailing slash:
echo e.g. http://www.mydomain.com/windows
echo
echo -n URL: ${} && read win_base_url
echo
echo netboot.xyz will attempt to load the following files:
echo ${win_base_url}/${winpe_arch}/bootmgr
echo ${win_base_url}/${winpe_arch}/bootmgr.efi
echo ${win_base_url}/${winpe_arch}/boot/bcd
echo ${win_base_url}/${winpe_arch}/boot/boot.sdi
echo ${win_base_url}/${winpe_arch}/sources/boot.wim
echo ${win_base_url}/configs/${win_image}/install.bat
echo ${win_base_url}/configs/configure.bat
echo ${win_base_url}/configs/winpeshl.ini
echo
prompt Press any key to return to Windows Menu...
goto windows

:win_install
isset ${win_base_url} && goto boot || echo URL not set... && goto url_set

:boot
imgfree
kernel http://${boot_domain}/wimboot
initrd ${win_base_url}/configs/${win_image}/install.bat install.bat
initrd ${win_base_url}/configs/configure.bat configure.bat
initrd ${win_base_url}/configs/winpeshl.ini winpeshl.ini
initrd -n bootmgr     ${win_base_url}/${winpe_arch}/bootmgr       bootmgr ||
initrd -n bootmgr.efi ${win_base_url}/${winpe_arch}/bootmgr.efi   bootmgr.efi ||      
initrd -n bcd         ${win_base_url}/${winpe_arch}/boot/bcd      bcd ||
initrd -n bcd         ${win_base_url}/${winpe_arch}/Boot/BCD      bcd ||
initrd -n boot.sdi    ${win_base_url}/${winpe_arch}/boot/boot.sdi boot.sdi ||
initrd -n boot.sdi    ${win_base_url}/${winpe_arch}/Boot/boot.sdi boot.sdi ||
initrd -n boot.wim    ${win_base_url}/${winpe_arch}/sources/boot.wim boot.wim
boot

:windows_exit
exit 0
```

Nu skal man desuden oprette disse mapper og filer på webserveren $$win_base_url$$:

```
- configs/
   - configure.bat
   - winpeshl.ini
   - $Win10_20H2_English_x64$/
      - install.bat
   - $Win10_1909_English_x64$/
      - install.bat
- x64/
   - *WinPE_x64*
- x86/
   - *WinPE_x86*
```

configure.bat

```
@echo off
Wpeutil InitializeNetwork
:START
ping -n 1 $$NET_SHARE_HOSTNAME$$
if errorlevel 1 GOTO START
net use m: $$NET_SHARE$$ /user:$$USERNAME$$ $$PASSWORD$$
install.bat
```

winpeshl.ini

```
[LaunchApp]
AppPath = configure.bat
```

Eksempel på install.bat

```
m:\Win10_20H2_English_x64\setup.exe
```

For at bruge custom menuen skal man blot sætte sin Github bruger i utilites menu og vælge sin nye brugerdefinerede menu.

Jeg valgte at erstatte "Windows" menu valget med min egen brugerdefineret windows menu.

![](https://i.imgur.com/HIoDZSP.png)


Resultat

![](https://i.imgur.com/z007A3w.gif)

![](https://i.imgur.com/AjKvQ2h.gif)



## Kilder
https://netboot.xyz/docs/docker/
https://netboot.xyz/docs/kb/pxe/windows/



