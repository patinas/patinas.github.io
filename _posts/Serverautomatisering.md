# Serverautomatisering

Forenkling og øgelse af produktivitet i server konfigurationer med automatisering.


# Installation
![](https://i.imgur.com/5Y68afL.png)

![](https://i.imgur.com/EHqrtY9.png)

Jeg vælger at prøve at sætte statiske IP’er på serverne ved hjælp af en mesh VPN ([ZeroTier](https://zerotier.com/)). (Systemet man forbinder fra skal selfølgelig også være på det virtuelle netværk.) På denne måde kan jeg have et virtuelt netværk i skyen som man kan tilgå fra flere steder.

Har lavet nogle scripts selv som jeg bruger til nem konfigurering af dette.

[https://github.com/patinas/windowsauto](https://github.com/patinas/windowsauto) (Selve koden brugt til at producere *.exe ligger der også.) Man skal lave ID om til sit eget i PowerShell koden.

![](https://i.imgur.com/knblqNO.png)

Overstående filer køres som administrator på serverne. Først køres “Application_Install_Script” og derefter “Remote_Desktop_Enable”.

Dette tilføjer en ekstra virtuel ethernet adapter med statisk IP til mine VM’s (Basale applikationer som Google Chrome, bliver også installeret). Den aktivere også RDP funktionen som man kan remote ind på serverne.

Nedenstående er PowerShell koden (Lav om på ID til sit eget og hvis man ikke ønsker applikationerne kan man bare slette navnene på dem)


```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

choco install zerotier-one googlechrome 7zip adobereader
# Change the network ID
zerotier-cli join 9f77fc393e977c16

# Firewall Rules
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
```

Dette gør man hvis man vil konvertere *.ps1 til *.exe

```
Set-ExecutionPolicy Bypass -Scope Process -Force;
Install-Module ps2exe
Import-Module ps2exe
Invoke-ps2exe "C:\Users\user\Downloads\Windows Deployment-20211220T121527Z-001\Windows Deployment\Remote_Desktop_Enable.ps1" "C:\Users\user\Downloads\Windows Deployment-20211220T121527Z-001\Windows Deployment\Remote_Desktop_Enable.exe"
```

IP på det virtuelle NIC

![](https://i.imgur.com/MSriN4J.png)


# IP PLAN



| Navn | IP | 
| -------- | -------- | 
| WinSrv01     | 192.168.192.114     | 
| WinSrv02    | 192.168.192.134     | 
| Win11    | 192.168.192.64     | 



# Del 1

Tilføjer rollerne som opgaven beskriver

![](https://i.imgur.com/0x7BrbA.png)

Vælger at kalde domænet “andreas.local”

(Vælger at tage snapshots igennem hele processen, hvis noget går galt.)

Under IP indstillinger på WinSrv02 peger jeg på DC serveren (WinSrv01) som DNS Server.

![](https://i.imgur.com/0E7Ln5k.png)

Tilføjer WinSrv02 (Server 2) til domænet

![](https://i.imgur.com/Ir87LYZ.png)

# Del 2

Opretter en RLZ zone på WinSrv01 (Server 1).

Tools >> DNS

Opret en RLZ zone.

![](https://i.imgur.com/Z1dVx93.png)

Da jeg kun bruger en DNS server kan jeg lade nedenstående være som det er.

![](https://i.imgur.com/FkYioK0.png)

Nedenstående beholder jeg også som det samme.

![](https://i.imgur.com/tduS9rc.png)


“Network ID” er de 3 første oktetter i mit netværk.


![](https://i.imgur.com/IGfCr7s.png)




Da dette er et test miljø giver jeg adgang til alle.



![](https://i.imgur.com/ZecJVf8.png)




# Del 3

Opret en GPO og tilgå redigering af den.


![](https://i.imgur.com/CuFTijw.png)

![](https://i.imgur.com/9H05sz9.png)


Som standard er PowerShell.exe placeret i denne mappe:

%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe

![](https://i.imgur.com/ylpoIjm.png)



Dette er resultatet

![](https://i.imgur.com/ZKHVoJq.png)





Nu kan man køre PowerShell ISE men ikke standard PowerShell applikationen.


# Del 4

CMDlets er en slags wrapper (en package) for C# kode som gør at det nemmere og hurtigere at arbejde med PowerShell ISE dog giver det også mindre kontrol over koden.

Opretter en ny Organizational Unit


```
New-ADOrganizationalUnit -Name "TestUsers" -Path "DC=andreas,DC=local"
```


Opretter en ny computer i OU


```
New-ADComputer -Name "TESTPC" -Path "OU=TestUsers,DC=andreas,DC=local"
```


Opretter en ny bruger med brugernavn “test2”


```
New-ADUser -Name "TestUser 2" -GivenName "Test" -Surname "User2" -SamAccountName "test2" -UserPrincipalName "test2@andreas.local" -Path "OU=TestUsers,DC=andreas,DC=local" -AccountPassword(Read-Host -AsSecureString "Input Password") -Enabled $true
```



# Del 5

Alias i PowerShell kan bruges til at forkorte et langt command eller bare gøre det nemmere at huske commands. Måden det fungere på er på en måde en slags oversættelse fra en CMDlet til et alias ord. Se nedenstående for at få bedre forståelse.

Jeg vælger at sætte en alias for command der giver mig NIC oversigt.


```
Set-Alias -name NIC -Value Get-NetAdapter
```


Hvis jeg skriver nedenstående kommer mine NIC’s frem.


```
NIC
```


Dette command, ved hjælp af en pipe eksportere mine alias, til en tekst fil på mit skrivebord.


```
Get-Alias | Out-File C:\Users\Administrator\Desktop\PSAlias.txt
```



# Del 6

Skifter navn fra “WinSrv02” til “WinSrv02Demo” og tilbage igen


```
Rename-Computer -NewName "WinSrv02Demo" -DomainCredential andreas.local\Administrator -Restart
```


![](https://i.imgur.com/6Muyfia.png)





Skifter tilbage til det originale navn, da jeg synes, det er et mere passende navn.


```
Rename-Computer -NewName "WinSrv02" -DomainCredential andreas.local\Administrator -Restart
```



# Del 7

Nedenstående command gør, at der bliver tjekket hvilke services kører og eksporterer resultatet til en tekst fil på skrivebordet. Service listen bliver sorted alfabetisk.


```
Get-Service | Sort-Object -Property Name | Where-Object {$_.Status -eq "Running"} | Out-File "C:\Users\Administrator\Desktop\Services.txt"
```



# Del 8

Nedenstående script opretter de nødvendige mapper, efter opgavens specifikationer.


```
ForEach ($Geo in ("Odense", "Vejle", "Svendborg"))
    {
        New-Item -ItemType Directory -Path C:\Users\Administrator\Desktop\Firma\$Geo -Force
    }

ForEach ($Afdeling in ("Salg", "Marketing", "Produktion"))
    {
        New-Item -ItemType Directory -Path C:\Users\Administrator\Desktop\Firma\Odense\$Afdeling -Force
        New-Item -ItemType Directory -Path C:\Users\Administrator\Desktop\Firma\Vejle\$Afdeling -Force
        New-Item -ItemType Directory -Path C:\Users\Administrator\Desktop\Firma\Svendborg\$Afdeling -Force
    }
```

# Del 9

Først skal jeg bruge et værktøj som Excel til at lave CSV filen. Jeg vælger at bruge chocolatey til installation, da jeg skal ikke interegere med installationen.

Installation af chocolatey igennem mit custom script. Husk at læse min readme section i github inden. Biver også henvist til i installation's sektionen.
https://github.com/patinas/windowsauto

```
choco install office365business
```

![](https://i.imgur.com/aU7b85b.png)

Bruger nedenstående PS script som eksporterer alle OU'erne og deres struktur.

```
$OUs=Get-ADOrganizationalUnit -Filter * | select name,DistinguishedName,@{n=’OUPath’;e={$_.distinguishedName -replace '^.+?,(CN|OU|DC.+)','$1'}},@{n=’OUNum’;e={([regex]::Matches($_.distinguishedName, “OU=” )).count}} | Sort OUNum | export-csv C:\Temp\Export.csv -NoTypeInformation
```

Derefter tester jeg med at slette OU'erne og importerer dem med nedenstående kommando.

```
$OUs = import-csv C:\Temp\Export.csv
ForEach ($OU in $OUs) 
          {New-ADOrganizationalUnit -Name $OU.Name -Path $OU.OUPath}
```

Bruger guiden fra websiden nedenstående
> https://stephanmctighe.com/2020/07/02/exporting-and-importing-active-directory-ou-structure/

Resultat
![](https://i.imgur.com/GuvTanA.png)

# Del 10

Jeg laver en CSV fil med 35 brugere som opgaven beskriver, og kalder den Users.csv og gemmer den her - C:\temp\Users.csv 

![](https://i.imgur.com/p2eGXVq.png)


Med nedenstående script importer jeg alle brugerne til min OU.

```
# Import active directory module for running AD cmdlets
Import-Module ActiveDirectory
  
# Store the data from NewUsersFinal.csv in the $ADUsers variable
$ADUsers = Import-Csv C:\temp\Users.csv -Delimiter ";"

# Define UPN
$UPN = "andreas.local"

# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {

    #Read user data from each field in each row and assign the data to a variable as below
    $username = $User.username
    $password = $User.password
    $firstname = $User.firstname
    $lastname = $User.lastname
    $initials = $User.initials
    $OU = $User.ou #This field refers to the OU the user account is to be created in
    $email = $User.email
    $streetaddress = $User.streetaddress
    $city = $User.city
    $zipcode = $User.zipcode
    $state = $User.state
    $country = $User.country
    $telephone = $User.telephone
    $jobtitle = $User.jobtitle
    $company = $User.company
    $department = $User.department

    # Check to see if the user already exists in AD
    if (Get-ADUser -F { SamAccountName -eq $username }) {
        
        # If user does exist, give a warning
        Write-Warning "A user account with username $username already exists in Active Directory."
    }
    else {

        # User does not exist then proceed to create the new user account
        # Account will be created in the OU provided by the $OU variable read from the CSV file
        New-ADUser `
            -SamAccountName $username `
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Initials $initials `
            -Enabled $True `
            -DisplayName "$lastname, $firstname" `
            -Path $OU `
            -City $city `
            -PostalCode $zipcode `
            -Country $country `
            -Company $company `
            -State $state `
            -StreetAddress $streetaddress `
            -OfficePhone $telephone `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -AccountPassword (ConvertTo-secureString $password -AsPlainText -Force) -ChangePasswordAtLogon $True

        # If user is created, show message.
        Write-Host "The user account $username is created." -ForegroundColor Cyan
    }
}

Read-Host -Prompt "Press Enter to exit"
```

Hvis man vil flytte en bruger med PS bruger man nedenstående kommando.

```
Get-ADUser -Identity $Brugernavn | Move-ADObject -TargetPath "OU=Marketing,OU=Odense,OU=Brugere,DC=andreas,DC=local"
```

# Del 11

Opretter en fil med navnet "file.txt" (Bemærk filtypen *.txt)

![](https://i.imgur.com/zYl45wo.png)

Vil fjerne alle text filer fra en mappe men vil sikre mig at de rigtige filer bliver slettet. Derfor vælger jeg -WhatIf parameteret. Bruger nedenstående kommando for at gøre det.

```
Get-ChildItem -File *.txt -Recurse -LiteralPath C:\temp\ | Remove-Item -WhatIf
```

Resultat af kommando, hvor jeg kan se hvilke filer, der bliver slettet.

![](https://i.imgur.com/WhitF4B.png)


Hvis jeg fjerner -WhatIf switchen bliver filen "file.txt" slettet.

```
Get-ChildItem -File *.txt -Recurse -LiteralPath C:\temp\ | Remove-Item
```

# Del 12

Kommandet nedenstående aktivere Deleted Objects containeren i AD Administrative Center

![](https://i.imgur.com/7uQCasf.png)


``` powershell
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target andreas.local
```

![](https://i.imgur.com/NiWZMpy.png)


Et eksempel på en bruger som blev slettet fra AD

![](https://i.imgur.com/XHk42lN.png)


# Del 13


Først sætter jeg et password på den lokale Administrator bruger så jeg kan logge ind efter jeg har forladt domæne.

![](https://i.imgur.com/29II8w0.png)

Gør overstående med PowerShell

``` powershell
$Password = Read-Host -AsSecureString
Set-LocalUser -Name "Administrator" -Password $Password

# Nedenstående for at forlade domæne og genstarte serveren.

remove-computer -credential andreas.local\Administrator -passthru -verbose

restart-computer
```
Resultat
![](https://i.imgur.com/TIZq9Ij.png)


Så lavet nedenstående PS kommando for at joine domæne igen.

``` powershell
Add-Computer -DomainName andreas.local -Restart
```

Resultat
![](https://i.imgur.com/JKTTSrF.png)


# Del 14

Dette setup er lidt anderledes da jeg bruger ZeroTier som interface, men princippet er det samme, hvis man vil bruge den konventionelle metode.

``` powershell
# Install the role
Install-WindowsFeature -Name 'DHCP' –IncludeManagementTools

# Bind to correct interface
Set-DhcpServerv4Binding -BindingState $True -InterfaceAlias "ZeroTier One [9f77fc393e977c16]"

# Set the scope (in my case - 49 IP's)
Add-DhcpServerV4Scope -Name "DHCP Scope" -StartRange 192.168.0.150 -EndRange 192.168.0.200 -SubnetMask 255.255.255.0

# If you want to use it with a router/firewall
# Set-DhcpServerV4OptionValue -DnsServer 192.168.0.10 -Router 192.168.1.1

# Set the lease time (The below is 1 hour)
Set-DhcpServerv4Scope -ScopeId 192.168.0.10 -LeaseDuration 1.00:00:00

# Assign Security Groups
Get-DhcpServerInDC
netsh dhcp add securitygroups
# Restart the service
Restart-service dhcpserver
Add-DhcpServerInDC -DnsName "WinSrv01.andreas.local" -IPAddress 192.168.0.10
Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
```

Resultat (på klient)
![](https://i.imgur.com/3RPoY6E.png)


# Del 15

FSMO Rollerne er nogle roller en eller flere af ens DC Servere får. Standard rollerne er 5, de 2 første - Schema Master og Domain Naming Master er forrest wide det vil på top-level (f.eks. flere domæner) og RID Master, PDC Emulator og Infrastructure Master er på domæne niveau (på et specifikt domæne).



## Schema Master

Denne rolle står for management af brugerinformationer som kan anvendes på et objekt i AD databasen.


## Domain Naming Master

Denne rolle sørger for at 2 domæner ikke har det samme navn.


## RID Master

Denne rolle er ansvarlig for behandling af RID pool requests fra alle DC'er. Når f.eks. skal flytte et objekt fra et domæne til et andet.


## PDC Emulator

PDC-emulatoren reagerer på authentication requests, ændrer adgangskoder og administrerer Group Policy Objects.


## Infrastructure Master

Rollen - Infrastructure Master oversætter Globally Unique Identifiers (GUID), SID'er og Distinguished Names (DN) mellem domæner. Hvis du har flere domæner i din skov, er Infrastructure Master mellemanden.


Nedestående PS, kan bruge for at se hvilke roller ens DC har.

``` powershell
Get-ADForest andreas.local
```

Resultat af kommando
![](https://i.imgur.com/5fEWUa6.png)

Man kan ekstrapellere fra overstående screenshot at min DC har 2 roller - Schema Master og Domain Naming Master som er forrest roller.
