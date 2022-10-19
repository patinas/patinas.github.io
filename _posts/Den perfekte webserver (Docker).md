
# Den perfekte webserver (Docker)

## Forudsætninger
- Ubuntu Server 20.4 installeret og opdateret med statisk IP.
- Root adgang ("sudo -i")


## Docker og Portainer

Vælger selv at lave et lille bash script som gør det nemmere at installere næste gang, men kan sagtens, installere manuelt.

```
#!/bin/sh

while true; do ping -c1 www.google.com > /dev/null && break; done

sudo apt update && sudo apt upgrade -y
sudo apt install curl -y


sudo apt install docker.io docker-compose -y
sudo systemctl enable docker
sudo systemctl start docker

sudo docker run -d \
--name="portainer" \
--restart on-failure \
-p 9000:9000 \
-p 8000:8000 \
-v /var/run/docker.sock:/var/run/docker.sock \
-v portainer_data:/data \
portainer/portainer-ce:latest

sudo chmod +x portainer.sh

echo Done

exit
```


Bruger Portainer som en nem måde at se om mine containers kører eller hvis der skal ændres noget i konfigurationerne. Det første man ser når man besøger nedenstående side er bruger oprettelse i portainer - Man vælger bare hvad brugeren og koden skal være.

Bruger nedenstående for at åbne portainer web interface.
http://IP_PÅ_HOST_MASKINE:9000/

Mit setup.
http://192.168.1.11:9000/

Nedenstående sætter jeg min IP - bliver relevant senere.
![](https://i.imgur.com/OHeTjiA.gif)


Nedenstående kan man se hvilke containers kører og om der er problemer med setup af containers.
![](https://i.imgur.com/v4FGrrX.gif)


## LAMP

Laver et script til LAMP installation og til noget af konfigureringen. Scriptet tilføjer 3 containers MySQL, PHPMyAdmin og Apache med PHP funktionalitet.

```
#!/bin/sh
while true; do ping -c1 www.google.com > /dev/null && break; done
sudo apt update && sudo apt upgrade -y
sudo chmod u+x *.sh
cd ~/

mkdir -p ~/docker/lamp/html
cd ~/docker/lamp

sudo cat > php.Dockerfile <<EOF
FROM php:7.3.3-apache
RUN docker-php-ext-install mysqli pdo pdo_mysql
EXPOSE 80
EOF

sudo cat > docker-compose.yaml <<EOF
version: "3.7"
services:
  demo01:
    build:
      dockerfile: php.Dockerfile
      context: .
    restart: always
    volumes:
      - "./html/:/var/www/html/"
    ports:
      - "8080:80"
  demo02:
    build:
      dockerfile: php.Dockerfile
      context: .
    restart: always
    volumes:
      - "./html2/:/var/www/html/"
    ports:
      - "8082:80"
  mysql-server:
    image: mysql:8.0.19
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: app
    volumes:
      - mysql-data:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:5.0.1
    restart: always
    environment:
      PMA_HOST: mysql-server
      PMA_USER: root
      PMA_PASSWORD: secret
    ports:
      - "5000:80"
volumes:
  mysql-data:
EOF

docker-compose up -d
```


Åbner PHPMyAdmin og tilgøjer en bruger med tilhørende database med følgende indstillinger.
http://192.168.1.11:5000/
    
![](https://i.imgur.com/Z1iEOix.png)

    
"html" mappen er hvor webside fillerne skal ligge.

```
cd ~/docker/lamp/html
```

Laver en PHP fil for at teste PHP funktionalitet.

```
micro php_info.php
```

    
```
<?php

// Show all information, defaults to INFO_ALL
phpinfo();

// Show just the module information.
// phpinfo(8) yields identical results.
phpinfo(INFO_MODULES);

?>
```
    
Laver en index fil og tilføjer nedenstående for at teste forbindelse til MySQL databasen.    
    
```
micro index.php
```

    
```
<?php                                                                                                                                                                                         
# Fill our vars and run on cli                                                                                                                                                                
# $ php -f db-connect-test.php                                                                                                                                                                
                                                                                                                                                                                              
$dbname = 'user01';                                                                                                                                                                             
$dbuser = 'user01';                                                                                                                                                                             
$dbpass = 'Root1234!';                                                                                                                                                                        
$dbhost = 'mysql-server';                                                                                                                                                                     
                                                                                                                                                                                              
$link = mysqli_connect($dbhost, $dbuser, $dbpass) or die("Unable to Connect to ");                                                                                                   
mysqli_select_db($link, $dbname) or die("Could not open the db ");                                                                                                                   
                                                                                                                                                                                              
$test_query = "SHOW TABLES FROM $dbname";                                                                                                                                                     
$result = mysqli_query($link, $test_query);                                                                                                                                                   
                                                                                                                                                                                              
$tblCnt = 0;                                                                                                                                                                                  
while($tbl = mysqli_fetch_array($result)) {                                                                                                                                                   
  $tblCnt++;                                                                                                                                                                                  
  #echo $tbl[0]."<br />";                                                                                                                                                                   
}                                                                                                                                                                                             
                                                                                                                                                                                              
if (!$tblCnt) {                                                                                                                                                                               
  echo "There are no tables<br />";                                                                                                                                                         
} else {                                                                                                                                                                                      
  echo "There are $tblCnt tables<br />";                                                                                                                                                    
}                                                                                                                                                                                             
?>
```



Hvis det hele er funktionelt skal nedenstående vises. (Den forbinder til databasen men ingen tables er oprettet endnu)
    
![](https://i.imgur.com/62ocgAZ.png)


Jeg ændrer på host porten for apache/PHP webserveren. Gør dette så port 80 kan bruges til proxy containeren, som jeg skal sættes op senere.
![](https://i.imgur.com/YmtSLo9.gif)

Apache 1
http://192.168.1.11:8080/
    
Apache 2
http://192.168.1.11:8081/

På Apache 2 containeren mapper jeg også webside mappen til en anden mappe inde i "/root/docker/lamp/"
![](https://i.imgur.com/CFjQ5cC.png)


Nedenstående gøres **også** på Apache 1.
    
```
micro ~/root/docker/lamp/html2/index.php
```
    
```
<!DOCTYPE html>
<html>
	<head>
		<title>UNDER CONSTRUCTION 02</title>
	</head>

	<body>

		<h1>UNDER CONSTRUCTION 02</h1>

	</body>
</html>
```
    
Resultat
![](https://i.imgur.com/feF0dWV.gif)


## Proxy

Laver et bash script igen som sætter min proxy op. Kan også laves manuelt. Dette script passer ikke med alle setups!

Load balancer
http://192.168.1.11/

Hver individuel webside
http://192.168.1.11/demo01
http://192.168.1.11/demo02

SSL fungerer ikke kun på https://192.168.1.11/ (forsiden) - Nåede ikke at fejlfinde en løsning.

```
#!/bin/sh
while true; do ping -c1 www.google.com > /dev/null && break; done
sudo apt update && sudo apt upgrade -y
sudo chmod u+x *.sh
cd ~/

apt install apache2 -y
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests
sudo systemctl restart apache2

cd /etc/apache2/sites-available
sudo rm 000-default.conf


sudo cat > demo.conf <<EOF
	<Proxy balancer://mycluster>
        # Define back-end servers:

        # Server 1
        BalancerMember http://0.0.0.0:8080/
        
        # Server 2
        BalancerMember http://0.0.0.0:8082/
    </Proxy>
    
    <VirtualHost *:*>

		ProxyPreserveHost On

		ProxyPass /demo01 http://0.0.0.0:8080/
		ProxyPassReverse /demo01 http://0.0.0.0:8080/

		ProxyPass /demo02 http://0.0.0.0:8082/
		ProxyPassReverse /demo02 http://0.0.0.0:8082/

		ProxyPass /joomla http://0.0.0.0:8888/
		ProxyPassReverse /joomla http://0.0.0.0:8888/
		
    
        # Apply VH settings as desired
        # However, configure ProxyPass argument to
        # use "mycluster" to balance the load
        
        ProxyPass / balancer://mycluster
    </VirtualHost>
EOF

# SSL

sudo a2enmod ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

sudo cat > demo_ssl.conf <<EOF
    <VirtualHost *:443>
    
        SSLEngine On
        
        # Set the path to SSL certificate
        # Usage: SSLCertificateFile /path/to/cert.pem
   		SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
   		SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
        
        
        # Servers to proxy the connection, or;
        # List of application servers:
        # Usage:
        # ProxyPass / http://[IP Addr.]:[port]/
        # ProxyPassReverse / http://[IP Addr.]:[port]/
        # Example: 
        ProxyPass / http://0.0.0.0:8080/
        ProxyPassReverse / http://0.0.0.0:8080/

		ProxyPass / http://0.0.0.0:8082/
		ProxyPassReverse / http://0.0.0.0:8082/	        

		ProxyPass / http://0.0.0.0:8888/
		ProxyPassReverse / http://0.0.0.0:8888/	        
        
        # Or, balance the load:
        ProxyPass / balancer://balancer_cluster_name
    
    </VirtualHost>
EOF


sudo a2ensite demo.conf
sudo a2ensite demo_ssl.conf
sudo systemctl reload apache2
```

    
## DNS

Man skal huske at sætte DNS serveren peger på til sig selv.
I dette eksempel: 192.168.1.11

![](https://i.imgur.com/GSGvaoX.png)

Man skal også gøre det direkte på klient eller hele netværket på routeren. Jeg vælger at gøre det på routeren.

![](https://i.imgur.com/BFFvBjh.png)

Nedenstående metode, finder jeg som den nemmeste, til setup af DNS.

Hent DEB package

```
wget https://prdownloads.sourceforge.net/webadmin/webmin_1.984_all.deb
```



**Kilde for DEB package**

https://www.webmin.com/download.html

![](https://i.imgur.com/SbF5EtQ.png)



Installation af DEB, hvor alle dependencies også bliver opfyldt. 

```
sudo apt install ./webmin_1.984_all.deb
```


Installere Bind

```
sudo apt install bind9
```

Overstående i et bash script. (Hvis man bruger "root" brugeren, skal man huske at oprette en kode, så man kan logge ind.)

```
sudo -i passwd
```

```
#!/bin/sh
while true; do ping -c1 www.google.com > /dev/null && break; done
sudo apt update && sudo apt upgrade -y
sudo chmod u+x *.sh
cd ~/

sudo apt update
wget https://prdownloads.sourceforge.net/webadmin/webmin_1.984_all.deb
sudo apt install ~/webmin_1.984_all.deb -y
sudo apt install bind9 -y
sudo rm webmin_1.984_all.deb
```



Åbner web-browser og går ind på nedenstående inden for netværk ("192.168.1.11" er min web server, i dette eksempel).

https://192.168.1.11:10000

Brug samme bruger + password som på serveren for at logge ind. 

![](https://i.imgur.com/jAwKpza.png)

"192.168.192.217" er fra min ZeroTier client som kører på maskinen så jeg kan manage serveren ude fra netværket.


Når jeg er logget ind trykker jeg "Refresh Modules"

![](https://i.imgur.com/ZK7TanP.png)


Laver en ny master zone.

![](https://i.imgur.com/s7uq0nr.png)


Kalder min side "demo.test" og husker at sætte en email.

![](https://i.imgur.com/2GT6dQv.png)


Først vælger følgende indstillinger i "Zone Options".

![](https://i.imgur.com/jkBvKgW.gif)


Trykker på "Address".

![](https://i.imgur.com/XAXMEUC.png)


Sætter nogle records ind, som peger på DNS serveren - "192.168.1.10" i mit eksempel.

![](https://i.imgur.com/jP7QpZs.png)


Hvis man har problemer med at starte BINDDNS.

```
named -g -c /dev/null
```


## Joomla

Til installation af Joomla, vælger jeg også at lave et lille script, som installere en MySQL database og Joomla i 2 containers.

```
#!/bin/sh
while true; do ping -c1 www.google.com > /dev/null && break; done
sudo apt update && sudo apt upgrade -y
sudo chmod +x joomla_docker.sh
sudo docker pull joomla
sudo docker pull mysql
sudo docker run --name joomla_db -d -e MYSQL_ROOT_PASSWORD=test mysql
sudo docker run --name joomla_website --link joomla_db:mysql -d -p 8888:80 joomla
```

Husker at bruge samme credentials når jeg linker til databasen ved Joomla's installations-web-interface ("test" som kode).

I Joomla's installations-web-interface, når man forbinde til database.
- I stedet for "localhost" --> "joomla_db"
- Brugernavn --> "root"
- Kode --> "test"

Resultat

Administrations-Dashboard
![](https://i.imgur.com/TxtC05v.png)

Demo side
![](https://i.imgur.com/pWMe3nc.png)


## .htaccess og .htpasswd

```
mkdir -p /etc/apache2/auth/
```

:::success
sudo micro /etc/apache2/auth/.htpasswd
:::

Bruger nedenstående side til generering af .htpasswd indhold. Der er også andre metoder til generering af cryptering, i dette eksempel bruger nedenstående website.

https://www.askapache.com/online-tools/htpasswd-generator/

I nedenstående eksempel hedder brugeren "admin" og password "Root1234!"

![](https://i.imgur.com/guvPtwt.png)

Kopierer nedenstående ind i /etc/apache2/auth/.htpasswd filen.

![](https://i.imgur.com/1dVqTPN.png)


Nu laver jeg en .htaccess fil, hvor man skal bruge brugernavn og kode for at besøge siden "domain1.com". Henviser også til .htpasswd filen hvor bruger credentials ligger.

:::success
sudo micro /var/www/domain1.com/public_html/.htaccess 
:::

```
AuthType basic
AuthName "restricted area"
AuthUserFile "/etc/apache2/auth/.htpasswd"
require valid-user
```


:::success
sudo systemctl reload apache2
:::

Tester om det virker. (Åbner siden i incognito mode, da nogle gange kan der være problemer med cache/cookies)

![](https://i.imgur.com/3JmDiKT.png)















## Installation af LAMP

### Apache

Opdatering af repositories og installation af Apache.
:::success
sudo apt update
sudo apt install apache2
:::


Åbner for de rette firewall porte i den indbyggede Ubuntu firewall.
:::success
sudo ufw allow in "Apache Full"
:::

Man skulle nu være i stand til at se standard apache-websiden ved at besøge sin server IP. Man skal huske at det **ikke** er ens public IP, hvis serveren er forbundet til det lokale netværk (LAN).

http://server_ip_addresse

For at se hvad serverens IP er.
:::success
ip a
:::


![](https://i.imgur.com/xGjQd4J.png)


### MySQL

:::success
sudo apt-get install mysql-server
mysql_secure_installation
:::


- Indtast "n", når du bliver spurgt, om du vil installere VALIDATE PASSWORD PLUGIN. 
- Indtast "n", når du bliver spurgt, om du vil ændre root MySQL-adgangskoden.
- Indtast "y" for resten af spørgsmålene.


### PHP

:::success
sudo apt install php libapache2-mod-php
:::


Dernæst vil vi bede Apache om at lede efter .php-filer, før vi leder efter .html-filer.

:::success
sudo nano /etc/apache2/mods-enabled/dir.conf
:::


```
<IfModule mod_dir.c>
DirectoryIndex index.php index.html index.cgi index.pl index.php index.xhtml index.htm
</IfModule>
```

Derefter genstarter vi Apache service.

:::success
sudo systemctl restart apache2
:::





## Apache Konfiguration

Nedenstående har jeg valgt som mappe-struktur, til de 2 websider.

```
/var/www/
├── domain1.com
│   └── public_html
├── domain2.com
│   └── public_html
```


Eksempel mappe oprettelse.

:::success
sudo mkdir -p /var/www/domain1.com/public_html
:::


Opretter den nedenstående fil og bruger noget HTML, som test.

:::success
sudo nano /var/www/domain1.com/public_html/index.html
:::

```
<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Welcome to domain1.com</title>
  </head>
  <body>
    <h1>Success! domain1.com home page!</h1>
  </body>
</html>
```

For at undgå problemer med rettigheder laver jeg nedenstående command hvor bruger "user" er min bruger.

:::success
sudo chown -R user: /var/www/domain1.com
:::


Nu vælger jeg at sætte virtual hosts op.

:::success
sudo nano /etc/apache2/sites-available/domain1.com.conf
:::

```
<VirtualHost *:80>
    ServerName domain1.com
    ServerAlias www.domain1.com
    ServerAdmin webmaster@domain1.com
    DocumentRoot /var/www/domain1.com/public_html

    <Directory /var/www/domain1.com/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/domain1.com-error.log
    CustomLog ${APACHE_LOG_DIR}/domain1.com-access.log combined
</VirtualHost>
```

Aktivere den nye virtuelle host

:::success
sudo a2ensite domain1.com
:::


Ser om der er syntax fejl i min config.

:::success
sudo apachectl configtest
:::

```
Syntax OK
```

Genstarter Apache.

:::success
sudo systemctl restart apache2
:::


Opretter en ny master zone og tilføjer serveren som vist nedenstående i webmin (Ligesom under BindDNS afsnittet.)

![](https://i.imgur.com/9MydWVa.png)


Tester om det virker i mit netværk.

![](https://i.imgur.com/gl6AnwD.png)


Man kan også lave virtuelle hosts direkte i Webmin, som kan i nogle tilfælde være hurtigere. Laver domain2.com med Webmin værktøjet.

![](https://i.imgur.com/I4By3l7.png)


![](https://i.imgur.com/F3mFr1h.png)

## Proxy

Bruger Webmin til installation af nogle Apache plugins. Understående vælger jeg modulerne som skal bruges til mod_proxy plugin som er en simpel reverse proxy plugin til Apache. 

![](https://i.imgur.com/suwJrUc.png)

Moduler som skal bruges til mod_proxy
* proxy
* proxy_http
* proxy_balancer
* lbmethod_byrequests

![](https://i.imgur.com/NndzmyA.png)


:::success
cd /etc/apache2/sites-available
:::

Opretter en virtual host mere som skal være proxy for 2 andre virtuelle hosts. (I stedet for "nano" bruger jeg "micro" som også er en terminal text editor - https://micro-editor.github.io/ - Dette er ikke et krav!)

:::success
sudo micro proxy.conf
:::

```
VirtualHost *:*>
    ProxyPreserveHost On

    ProxyPass / http://domain1.com:80/
    ProxyPassReverse / http://domain2.com:80/
</VirtualHost>
```

:::success
sudo a2ensite proxy.conf
:::

For at teste om det virker slukker jeg for virtuel host "domain1.com" og ser om den bruger "domain2.com" som failover.

:::success
sudo a2dissite domain1.com.conf
:::

:::success
systemctl reload apache2
:::


Eksemplet viser at det virker, når man besøger domain1.com som er nede går den over til domain2.com.

![](https://i.imgur.com/HIbNbFD.png)


## .htaccess og .htpasswd

:::success
sudo mkdir -p /etc/apache2/auth/
:::

:::success
sudo micro /etc/apache2/auth/.htpasswd
:::

Bruger nedenstående side til generering af .htpasswd indhold. Der er også andre metoder til generering af cryptering, i dette eksempel bruger nedenstående website.

https://www.askapache.com/online-tools/htpasswd-generator/

I nedenstående eksempel hedder brugeren "admin" og password "kode"

![](https://i.imgur.com/guvPtwt.png)

Kopierer nedenstående ind i /etc/apache2/auth/.htpasswd filen.

![](https://i.imgur.com/1dVqTPN.png)


Nu laver jeg en .htaccess fil, hvor man skal bruge brugernavn og kode for at besøge siden "domain1.com". Henviser også til .htpasswd filen hvor bruger credentials ligger.

:::success
sudo micro /var/www/domain1.com/public_html/.htaccess 
:::

```
AuthType basic
AuthName "restricted area"
AuthUserFile "/etc/apache2/auth/.htpasswd"
require valid-user
```


:::success
sudo systemctl reload apache2
:::

Tester om det virker. (Åbner siden i incognito mode, da nogle gange kan der være problemer med cache/cookies)

![](https://i.imgur.com/3JmDiKT.png)


## (CGI) Common Gateway Interface Scripting

På Ubuntu 20.04 er Apache som standard konfigureret til at tillade udførelse af CGI-scripts i den udpegede /usr/lib/cgi-bin-mappe. Man behøver ikke at ændre nogen Apache-konfigurationer.

Apaches CGI-modul skal aktiveres, før CGI-scripts kan køre. For at gøre dette skal man oprette et symbollink.

:::success
sudo ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/
:::

:::success
sudo systemctl restart apache2
:::

Laver et simpelt bash script.

:::success
sudo micro /usr/lib/cgi-bin/uptime.cgi
:::

```
#!/bin/bash
echo "Content-type: text/html" 
echo
apachectl status|grep uptime
```

:::success
sudo chmod 755 /usr/lib/cgi-bin/uptime.cgi
:::


Tester i en browser.

![](https://i.imgur.com/ZHG5P6Q.png)


## PHP info

For at se php information, vælger jeg at oprette en ny info.php fil i root mappen for website.

:::success
sudo micro /var/www/domain1.com/public_html/info.php
:::

Filen skal indeholde nedenstående indhold.

```
<?php
phpinfo();
?>
```

Resultat når man besøger siden.

![](https://i.imgur.com/U7XzS5S.png)


## Joomla

Installere de nødvendige dependencies

:::success
sudo apt install php zip libapache2-mod-php php-gd php-json php-mysql php-curl php-mbstring php-intl php-imagick php-xml php-bcmath php-gmp php-xmlrpc
:::

Opretter en database

:::success
sudo mysql -u root
:::

Når man er i mysql prompten, skal man oprette databasen. I dette eksempel bruger jeg "joomla" (databasenavn), "user" (databasebrugernavn) og "Root1234!" (databaseadgangskode).

```
CREATE DATABASE joomla;
CREATE USER 'user'@'localhost' IDENTIFIED BY 'Root1234!';
GRANT ALL PRIVILEGES ON joomla.* TO 'user'@'localhost';
FLUSH PRIVILEGES;
exit
```

Dernæst opdatere jeg php.ini-konfigurationsfilen for at øge filstørrelsen og hukommelsesgrænsen.

:::success
sudo nano /etc/php/7.4/apache2/php.ini
:::


```
memory_limit = 256M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 300
output_buffering = Off
```

Efter php.ini-filen er opdateret, downloader jeg den seneste Joomla-version ved hjælp af wget

:::success
wget https://downloads.joomla.org/cms/joomla3/3-9-24/Joomla_3-9-24-Stable-Full_Package.tar.gz
:::


Dernæst skal man lave en mappe til Joomla-filerne.

:::success
sudo mkdir /var/www/html/joomla
:::


Derefter udpakker jeg, ved hjælp af tar og flytter filerne til /var/www/html/joomla. (Man skal huske at versionen af Joomla kan have ændret sig siden, så nedenstående command kan variere)

:::success
sudo tar xzf Joomla_3-9-23-Stable-Full_Package.tar.gz -C /var/www/html/joomla
:::


Ændrer ejerskabet af Joomla-biblioteket, så jeg ikke løber ind i nogen rettigheds-problemer. I dette ekspempel hedder min sudo bruger "user"

:::success
sudo chown -R user:user /var/www/html/joomla
:::

Opretter et nyt DNS entry til Joomla, ved hjælp af BindDNS (ikke et krav). Samme metode som tidligere.

![](https://i.imgur.com/ShIktji.png)


Redigere virtual host, så det passer med DNS navnet.

![](https://i.imgur.com/CN0mw9x.png)


Ændre også den tidligere lavet proxy.conf fil.

:::success
sudo micro proxy.conf
:::


```
<VirtualHost *:*>
    ProxyPreserveHost On
        ProxyPass / http://myjoomla.com:80/
        ProxyPass / http://domain1.com:80/
        ProxyPass / http://domain2.com:80/
</VirtualHost>
```


Besøger siden http://myjoomla.com på en klient i netværket og går igennem installations-wizard.

![](https://i.imgur.com/lpm5nCG.png)


- Opretter administratorkonto
- Linker til database "joomla" oprettet tidligere.
- Sletter installations mappe fra server.

:::success
sudo rm -r /var/www/html/joomla/installation
:::


Tester med at besøge http://myjoomla.com og http://myjoomla.com/administrator (Bruger, tidligere oprettet administrator bruger og password.)


![](https://i.imgur.com/SJ2bqIY.png)



![](https://i.imgur.com/VgNCOon.png)


## Self-Signed SSL


Generering af SSL nøgle.
:::success
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
:::


Opsættning af DH parametre.
:::success
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
:::


Konfigurering af SSL krypteringen, hvor man indsætter nedenstående.
:::success
sudo micro /etc/apache2/conf-available/ssl-params.conf 
:::

```
SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
SSLProtocol All -SSLv2 -SSLv3
SSLHonorCipherOrder On
Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains"
Header always set X-Frame-Options DENY
Header always set X-Content-Type-Options nosniff
SSLCompression off
SSLSessionTickets Off
SSLUseStapling on
SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
```



Redigering af standard SSL Virtual Host, hvor nogle ændringer bliver lavet, som SSL certificate placeringerne.

:::success
sudo micro /etc/apache2/sites-available/default-ssl.conf
:::


```
<IfModule mod_ssl.c>
	<VirtualHost _default_:443>
		ServerAdmin webmaster@localhost

		DocumentRoot /var/www/html

		# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
		# error, crit, alert, emerg.
		# It is also possible to configure the loglevel for particular
		# modules, e.g.
		#LogLevel info ssl:warn

		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined

		# For most configuration files from conf-available/, which are
		# enabled or disabled at a global level, it is possible to
		# include a line for only one particular virtual host. For example the
		# following line enables the CGI configuration for this host only
		# after it has been globally disabled with "a2disconf".
		#Include conf-available/serve-cgi-bin.conf

		#   SSL Engine Switch:
		#   Enable/Disable SSL for this virtual host.
		SSLEngine on

		#   A self-signed (snakeoil) certificate can be created by installing
		#   the ssl-cert package. See
		#   /usr/share/doc/apache2/README.Debian.gz for more info.
		#   If both key and certificate are stored in the same file, only the
		#   SSLCertificateFile directive is needed.
		SSLCertificateFile	/etc/ssl/certs/apache-selfsigned.crt
		SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

		#   Server Certificate Chain:
		#   Point SSLCertificateChainFile at a file containing the
		#   concatenation of PEM encoded CA certificates which form the
		#   certificate chain for the server certificate. Alternatively
		#   the referenced file can be the same as SSLCertificateFile
		#   when the CA certificates are directly appended to the server
		#   certificate for convinience.
		#SSLCertificateChainFile /etc/apache2/ssl.crt/server-ca.crt

		#   Certificate Authority (CA):
		#   Set the CA certificate verification path where to find CA
		#   certificates for client authentication or alternatively one
		#   huge file containing all of them (file must be PEM encoded)
		#   Note: Inside SSLCACertificatePath you need hash symlinks
		#		 to point to the certificate files. Use the provided
		#		 Makefile to update the hash symlinks after changes.
		#SSLCACertificatePath /etc/ssl/certs/
		#SSLCACertificateFile /etc/apache2/ssl.crt/ca-bundle.crt

		#   Certificate Revocation Lists (CRL):
		#   Set the CA revocation path where to find CA CRLs for client
		#   authentication or alternatively one huge file containing all
		#   of them (file must be PEM encoded)
		#   Note: Inside SSLCARevocationPath you need hash symlinks
		#		 to point to the certificate files. Use the provided
		#		 Makefile to update the hash symlinks after changes.
		#SSLCARevocationPath /etc/apache2/ssl.crl/
		#SSLCARevocationFile /etc/apache2/ssl.crl/ca-bundle.crl

		#   Client Authentication (Type):
		#   Client certificate verification type and depth.  Types are
		#   none, optional, require and optional_no_ca.  Depth is a
		#   number which specifies how deeply to verify the certificate
		#   issuer chain before deciding the certificate is not valid.
		#SSLVerifyClient require
		#SSLVerifyDepth  10

		#   SSL Engine Options:
		#   Set various options for the SSL engine.
		#   o FakeBasicAuth:
		#	 Translate the client X.509 into a Basic Authorisation.  This means that
		#	 the standard Auth/DBMAuth methods can be used for access control.  The
		#	 user name is the `one line' version of the client's X.509 certificate.
		#	 Note that no password is obtained from the user. Every entry in the user
		#	 file needs this password: `xxj31ZMTZzkVA'.
		#   o ExportCertData:
		#	 This exports two additional environment variables: SSL_CLIENT_CERT and
		#	 SSL_SERVER_CERT. These contain the PEM-encoded certificates of the
		#	 server (always existing) and the client (only existing when client
		#	 authentication is used). This can be used to import the certificates
		#	 into CGI scripts.
		#   o StdEnvVars:
		#	 This exports the standard SSL/TLS related `SSL_*' environment variables.
		#	 Per default this exportation is switched off for performance reasons,
		#	 because the extraction step is an expensive operation and is usually
		#	 useless for serving static content. So one usually enables the
		#	 exportation for CGI and SSI requests only.
		#   o OptRenegotiate:
		#	 This enables optimized SSL connection renegotiation handling when SSL
		#	 directives are used in per-directory context.
		#SSLOptions +FakeBasicAuth +ExportCertData +StrictRequire
		<FilesMatch "\.(cgi|shtml|phtml|php)$">
				SSLOptions +StdEnvVars
		</FilesMatch>
		<Directory /usr/lib/cgi-bin>
				SSLOptions +StdEnvVars
		</Directory>

		#   SSL Protocol Adjustments:
		#   The safe and default but still SSL/TLS standard compliant shutdown
		#   approach is that mod_ssl sends the close notify alert but doesn't wait for
		#   the close notify alert from client. When you need a different shutdown
		#   approach you can use one of the following variables:
		#   o ssl-unclean-shutdown:
		#	 This forces an unclean shutdown when the connection is closed, i.e. no
		#	 SSL close notify alert is send or allowed to received.  This violates
		#	 the SSL/TLS standard but is needed for some brain-dead browsers. Use
		#	 this when you receive I/O errors because of the standard approach where
		#	 mod_ssl sends the close notify alert.
		#   o ssl-accurate-shutdown:
		#	 This forces an accurate shutdown when the connection is closed, i.e. a
		#	 SSL close notify alert is send and mod_ssl waits for the close notify
		#	 alert of the client. This is 100% SSL/TLS standard compliant, but in
		#	 practice often causes hanging connections with brain-dead browsers. Use
		#	 this only for browsers where you know that their SSL implementation
		#	 works correctly.
		#   Notice: Most problems of broken clients are also related to the HTTP
		#   keep-alive facility, so you usually additionally want to disable
		#   keep-alive for those clients, too. Use variable "nokeepalive" for this.
		#   Similarly, one has to force some clients to use HTTP/1.0 to workaround
		#   their broken HTTP/1.1 implementation. Use variables "downgrade-1.0" and
		#   "force-response-1.0" for this.
		BrowserMatch "MSIE [2-6]" \
				nokeepalive ssl-unclean-shutdown \
				downgrade-1.0 force-response-1.0

	</VirtualHost>
</IfModule>
```

Indstiller så http requests bliver redirected til https (Gøres på hver originale virtual host).

:::success
sudo micro /etc/apache2/sites-available/domain1.com.conf
:::

```
Redirect permanent "/" "https://domain1.com/"
```

Aktivering af SSL moduler i Apache.
:::success
sudo a2enmod ssl
:::

:::success
sudo a2enmod headers
:::



Jeg kopierer til navn, tilsvarende originale virtual host.
:::success
sudo cp default-ssl.conf ssl.domain1.com.conf
:::

Jeg deaktiverer standard SSL config. 
:::success
sudo a2dissite default-ssl.conf
:::


Laver de sidste ændringer i SSL .conf fil.
:::success
sudo micro ssl.domain1.com.conf
:::

```
ServerName domain1.com
DocumentRoot /var/www/domain1.com/public_html/
```

Aktivering af config.
:::success
sudo a2ensite ssl.domain1.com.conf
:::

**Processen skal gentages til de andre 2 websider.**


Aktivering af SSL indstilling.

:::success
sudo a2enconf ssl-params
:::

Hvis alt er i orden vil en configtest vise følgende resultat.

:::success
sudo apache2ctl configtest
:::

```
Syntax OK
```


Genstart af Apache service, så alle ændringer træder i kraft.

:::success
sudo systemctl restart apache2
:::



**MÅSKE DET HELE MED DOCKER**



--INSERT HERE--








