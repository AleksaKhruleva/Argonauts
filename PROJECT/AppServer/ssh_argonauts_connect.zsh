#!/bin/zsh

# sshfs webmaster@www.argonauts.online:/var/www.argonauts.online /Volumes/macOS/Users/hrulev/Google\ Drive/www.argonauts.online/_remote_site

#ssh -4 -L 3306:127.0.0.1:3306 -L 3321:127.0.0.1:3321 -L 3320:127.0.0.1:3320 argouser@www.argonauts.online

ssh -4 -L 3306:127.0.0.1:3306 argouser@www.argonauts.online

