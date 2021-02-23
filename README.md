# backup
Настраиваем бэкапы
Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client
Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:
- Директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB.
- Репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение
- Имя бекапа должно содержать информацию о времени снятия бекапа
- Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов
- Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.
- Написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение.



Установка borgbackup на обе машины и подготовка
Предварительно в вагрант файл добавим дополнительный диск sdb, с тем, для того чтобы потом на нем сделать точку монтирования под бекап.

Создаем директорию для резервных копий /var/backup
```ruby
[vagrant@backupserver ~]$ sudo mkfs.ext4 /dev/sdb
[vagrant@backupserver ~]$ sudo mkdir /var/backup/
[vagrant@backupserver ~]$ sudo mount /dev/sdb /var/backup/
[vagrant@backupserver ~]$ df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00   38G  675M   37G   2% /
devtmpfs                         1.4G     0  1.4G   0% /dev
tmpfs                            1.4G     0  1.4G   0% /dev/shm
tmpfs                            1.4G  8.5M  1.4G   1% /run
tmpfs                            1.4G     0  1.4G   0% /sys/fs/cgroup
/dev/sda2                       1014M   63M  952M   7% /boot
tmpfs                            285M     0  285M   0% /run/user/1000
/dev/sdb                         2.0G  6.0M  1.8G   1% /var/backup
```
Скачиваем бинарник с репозиторрия, добавив права на исполнение. Необходимо проделать на обоих машинах.
```ruby
[root@backupserver vagrant]# curl -L https://github.com/borgbackup/borg/releases/download/1.1.14/borg-linux64 -o /usr/bin/borg && chmod +x /usr/bin/borg
```
Создаем пользователя для borg:
```ruby
[root@backupserver vagrant]# useradd -m borg
```
Устанавливаем сам borg
```ruby
[root@backupserver vagrant]# yum install -y borgbackup
```
для авторизации через пароль задаем пароль borg
```ruby
[root@backupserver vagrant]# echo test1234 | passwd borg --stdin
[root@backupserver vagrant]# sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
[root@backupserver vagrant]# systemctl restart sshd
```
создадим ключ на клиенте
```ruby
[root@client ~]# ssh-keygen -b 2048 -t rsa -q -N '' -f ~/.ssh/id_rsa
[root@client ~]# sshpass -p test1234 ssh-copy-id -o StrictHostKeyChecking=no borg@192.168.10.101
[root@client ~]# borg init -e none borg@192.168.10.101:/var/backup/
```
скопируем заранее подготовленные файлы
```ruby
[root@client vagrant]# cp /vagrant/borg.service /etc/systemd/system/borg.service
[root@client vagrant]# cp /vagrant/borg.timer /etc/systemd/system/borg.timer
[root@client vagrant]# cp /vagrant/log_borg.conf /etc/logrotate.d/log_borg
```
Обновим конфигурацию systemd и запустим таймер:
```ruby
[root@client vagrant]# systemctl daemon-reload
[root@client vagrant]# systemctl enable borg.service
[root@client vagrant]# systemctl enable borg.timer
Created symlink from /etc/systemd/system/multi-user.target.wants/borg.timer to /etc/systemd/system/borg.timer.
[root@client vagrant]# systemctl start borg.service
[root@client vagrant]# systemctl start borg.timer
```

Создадим /etc/testdir с файлами внутри:
```ruby
[root@client ~]# mkdir /etc/testdir && touch /etc/testdir/testfile{01..05}
[root@client ~]# ll /etc/testdir/
total 0
-rw-r--r--. 1 root root 0 Feb 23 15:37 testfile01
-rw-r--r--. 1 root root 0 Feb 23 15:37 testfile02
-rw-r--r--. 1 root root 0 Feb 23 15:37 testfile03
-rw-r--r--. 1 root root 0 Feb 23 15:37 testfile04
-rw-r--r--. 1 root root 0 Feb 23 15:37 testfile05
```
Выполним задание бэкапа вручную:
```ruby
[root@client vagrant]# ./backup.sh
```
Посмотрим, что получилось
```ruby
[root@client vagrant]# borg list borg@192.168.10.101:/var/backup
Remote: Using a pure-python msgpack! This will result in lower performance.
Enter passphrase for key ssh://borg@192.168.10.101/var/backup/:
etc-client-2021-02-23_15:39:49 
```
Как видим всё работает

