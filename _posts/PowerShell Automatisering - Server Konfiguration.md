# PowerShell Automatisering - Server Konfiguration

- Ændring af navn
- Aktivering af "Remote Desktop"
- Skift af IP til statisk
- Ændring af time zone


![](https://i.imgur.com/IAgBGOG.png)

![](https://i.imgur.com/ji7AEGT.png)

![](https://i.imgur.com/kBA1yUt.png)

## På Windows Server Core


Giver en liste over roller der kan installeres
```
Get-WindowsFeature
```

Installation af Active Directory

```
Install-WindowsFeature -Name AD-Domain-Services
```

Oprettelse af domæne - i dette case test.local

```
Install-ADDSForest -DomainName test.local
```

Windows klient eller server - tilføjelse til domæne.

```
Add-Computer -DomainName test.local -Restart
```

Remote powershell session til core fra GUI windows server.
```
Enter-PSSession WinSrv01
```

Installation af ZeroTier Klient ("Global Switch"), med PowerShell.

Dette hjemmelavet script gør at man kan RDP ind igennem firewalls.

![](https://i.imgur.com/gPlyqzo.png)

```
Start-Process powershell -verb RunAs -ArgumentList ".\ZeroTier.ps1"

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

choco install zerotier-one

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

zerotier-cli join 9f77fc393e977c16
```

## Tilføjelse Windows Server Core til eksisterende GUI Windows Server


Add Servers
![](https://i.imgur.com/BbwqFDT.png)



Mulighed for tilføjelse af roller på hver server med GUI.
![](https://i.imgur.com/MdUM7KW.png)




## Ansible - Kør PowerShell Scripts fra en linux maskine/VM

Opdatering
```
sudo apt update
```

"root" bruger
```
sudo -i
```


Installation af Ansible.
```
sudo apt install ansible
```


Installation af Python-
```
sudo apt install python3
```


Oprettelse af inventory fil.
```
nano hosts.ini
```

Indhold af "hosts.ini".
```
[win] #This is the group name
192.168.1.15

[win:vars] # These are the group variables
ansible_user=Administrator
ansible_password="Root1234!"
ansible_port=5986
ansible_connection=winrm
ansible_winrm_scheme=https
ansible_winrm_server_cert_validation=ignore
ansible_winrm_kerberos_delegation=true
```


Test at kommunikation mellem windows og linux med WinRM.
```
ansible -i hosts.ini win -m win_ping
```


Oprettelse af Ansible playbook.
```
nano windows.yml
```

Indhold af playbook som gør powershell commands muligt.

Test med oprettelse af fil "testfile1.txt" og med indhold, "This is a text string."

```
---
- name: Manage Windows
  hosts: win
  tasks:
    - name: Run basic PowerShell script
      ansible.windows.win_powershell:
        script: |
         New-Item -Path . -Name "testfile1.txt" -ItemType "file" -Value "This is a text string."
```

Installation af Ansible windows moduler på Linux VM.
```
ansible-galaxy collection install ansible.windows
```


Udførelse og test af playbook.
```
ansible-playbook -i hosts.ini windows.yml
```

![](https://i.imgur.com/R0OmSGl.png)

















