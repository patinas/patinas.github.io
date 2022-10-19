# Cyber Sikkerhed - Hacking og Subnetting

## Kali Linux i Web browser
![](https://i.imgur.com/QZaw1ZQ.png)

Command til deployment af container.
``` bash
sudo docker run --rm -it --shm-size=4096m -p 6901:6901 -e VNC_PW=root kasmweb/core-kali-rolling:1.11.0 --user root
```

User : kasm_user
Password: root


**Link til dokumentation**
https://hub.docker.com/r/kasmweb/core-kali-rolling

