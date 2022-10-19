#!/bin/sh
git config pull.rebase false
git pull
git add .
git commit -m "init"
git push
