#!/bin/sh

export BORG_URL=ssh://borg@192.168.10.101/var/backup

borg create -v --stats $BORG_URL::'{hostname}-{now:%Y-%m-%d-%H-%M}' /etc

borg prune -v --list --keep-daily 90 --keep-monthly 12 $BORG_URL --prefix '{hostname}-' 

journalctl -u borg-backup.service -n 35 > /var/log/borg.log