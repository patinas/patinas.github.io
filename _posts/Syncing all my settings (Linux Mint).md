# Syncing all my settings (Linux Mint)

I want my settings to be the same on all my Linux Mint boxes. The way i solved this was with the help of rlcone and dconf.

I have made the script public on github. The link is under the Scripts section on my website with the name "Post Install on Linux (Ubuntu Based)"
https://www.theitguide.xyz/scripts/

## How to

The following, needs to be done on every machine you want to the settings migrated.

You will first obviously need to install rclone
```
sudo apt install rclone -y
```

Then you will need to setup a remote with a cloud storage service - I am using Google Drive. Use the command below and add a new remote, leaving the most at default (That is what I did).

```
sudo rclone config
```

To use my script the remote needs to be name "drive".

I am doing the following, so i don't need to be prompted to sudo password every time, use with care.

```
sudo visudo
```

Add the following to the end of the file and save it.

```
user ALL=(ALL) NOPASSWD: ALL
```

To test, open a new terminal, after closing all the open ones and run an update and see if it the sudo password prompt shows up.

```
sudo apt update && sudo apt upgrade -y
```
Lets get the script.

```
sudo apt install git -y
```

```
git clone https://github.com/patinas/post_install_linux
```
Make the folder contents executable.

```
sudo chmod +x post_install_linux/*
```


---

On the source computer you want to copy settings from.

```
./config_sync_upload.sh
```

On the destination computer you want the settings applied.

```
./config_sync_down.sh
```

Of course, because it is a script, you can use it in many different ways, for example it can run the download at start up and the upload on shutdown. This way you turn on the next machine you will have the settings from the previously turned off machine.


---

## The scripts

Upload

```
#!/bin/sh

mkdir ~/Sync/
mkdir ~/Scripts/

while true; do ping -c1 www.google.com > /dev/null && break; done
sudo apt update && sudo apt upgrade -y
sudo apt install dconf* -y
sudo apt update && sudo apt upgrade -y

## Backup settings
dconf dump / > cinnamon_desktop
mv cinnamon_desktop ~/Sync/

## Sync with google drive
sudo rclone sync -P ~/Sync/ drive:/Sync/
sudo rclone sync -P ~/Scripts/ drive:/Scripts/
``` 

Download

```
#!/bin/sh

mkdir ~/Sync/
mkdir ~/Scripts/

while true; do ping -c1 www.google.com > /dev/null && break; done
sudo apt update && sudo apt upgrade -y
sudo apt install dconf* -y
sudo apt update && sudo apt upgrade -y

## Sync with google drive
sudo rclone sync -P drive:/Sync/ ~/Sync/ 
sudo rclone sync -P drive:/Scripts/ ~/Scripts/ 

dconf load / < ~/Sync/cinnamon_desktop
```

