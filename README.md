# Tuto Master_Slave

https://mariadb.com/kb/en/setting-up-replication/

### Avoir installer docker et docker compose


## 1 / Lancer les 3 conatiners avec le docker-compose.yml

- Se rendre dans le dossier ou il y a le docker compose (cd tuto_Master_Slave)

```
docker compose up 
```
(si votre docker-compose.yml porte un autre nom : docker compose -f name.yml up )

- Vérifier la bonne création des 3 containers
``` 
yans@yans-IdeaPad-3-15IML05:~$ docker ps 
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS         PORTS                                                                                  NAMES
3556b2ddae97   yanseg/worms   "/usr/local/bin/entr…"   10 seconds ago   Up 8 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp, 0.0.0.0:19998->19999/tcp, :::19998->19999/tcp   WORDPRESS
0dbf36707800   mariadb        "docker-entrypoint.s…"   10 seconds ago   Up 9 seconds   3306/tcp                                                                               SQL-MASTER
fb7b2a96514f   mariadb        "docker-entrypoint.s…"   10 seconds ago   Up 9 seconds   3306/tcp                                                                               SQL-SLAVE01

```

## 2 / MASTER
- Se rendre  sur le docker master 
```
docker exec -it SQL-MASTER bash 
```

- Récupérer l adresse IP du container SQL-MASTER

docker inspect nom du container
```
 docker inspect SQL-MASTER
```
l'adresse est sur la fin "IPAddress": "172.21.0.3", (dans mon cas)


Une ligne de commande permet de récupéer l'IP. Par exemple pour le container SQL-MASTER
```
echo $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' SQL-MASTER)
```
Le script ipContainer.sh permet de le faire aussi 
```
./ipContainer.sh SQL-MASTER
```
```
L'adresse IP du conteneur 'SQL-MASTER' est : 172.21.0.3
```




- Se rendre sur le container SQL-MASTER 
```
docker exec -it SQL-MASTER bash 
```
- Se connecter à mariadb
```
 mariadb -u root -psomewordpress
```
- Puis suivre ces étapes :
```
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'bigs3cret';
```

```
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
```
```
SHOW MASTER STATUS;
```
```
MariaDB [(none)]> CREATE USER 'replication_user'@'%' IDENTIFIED BY 'bigs3cret';
Query OK, 0 rows affected (0.011 sec)

MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
Query OK, 0 rows affected (0.010 sec)

MariaDB [(none)]> SHOW MASTER STATUS;
+-------------------+----------+--------------+------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-------------------+----------+--------------+------------------+
| mysqld-bin.000002 |      685 |              |                  |
+-------------------+----------+--------------+------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> UNLOCK TABLES;
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> exit;
Bye
root@0fbac997549d:/# 
```

- Cela vous permet de récupérer toute les infos nécessaires pour préparer la requête SQL pour configurer les SLAVE.

- Comme j'ai noté l'IP de mon container et (172.21.0.3) et que j'ai récupérer ces infos  (mysqld-bin.000002 |  685) je peux déjà pres remplir ma requete SQL pour le slave.

```
CHANGE MASTER TO
  MASTER_HOST='172.21.0.3',
  MASTER_USER='replication_user',
  MASTER_PASSWORD='bigs3cret',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='mysqld-bin.000002',
  MASTER_LOG_POS=685,
  MASTER_CONNECT_RETRY=10;
```

## 3 / SLAVE
- Je me rend sur le slave 
```
docker exec -it SQL-SLAVE01 bash 
```
- Je me rend dans mariadb 
```
mariadb -u root -psomewordpress
```
- J'éxécute la requête SQL précédemment notée 
```
CHANGE MASTER TO
  MASTER_HOST='172.21.0.3',
  MASTER_USER='replication_user',
  MASTER_PASSWORD='bigs3cret',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='mysqld-bin.000002',
  MASTER_LOG_POS=685,
  MASTER_CONNECT_RETRY=10;
```


je vérifie bien que :

             Slave_IO_Running: Yes
             Slave_SQL_Running: Yes

(NB : ces informations serviront pour faire son script soi même en monitoring..)



## 4 / Résumé des commandes   

```
yans@yans-IdeaPad-3-15IML05:~$ docker ps 
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                                                                  NAMES
71ac447dd842   yanseg/worms   "/usr/local/bin/entr…"   21 seconds ago   Up 17 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp, 0.0.0.0:19998->19999/tcp, :::19998->19999/tcp   WORDPRESS
87cf7c948a50   mariadb        "docker-entrypoint.s…"   21 seconds ago   Up 18 seconds   3306/tcp                                                                               SQL-SLAVE01
0fbac997549d   mariadb        "docker-entrypoint.s…"   21 seconds ago   Up 18 seconds   3306/tcp                                                                               SQL-MASTER
yans@yans-IdeaPad-3-15IML05:~$ docker exec -it SGL-MASTER bash 
Error response from daemon: No such container: SGL-MASTER
yans@yans-IdeaPad-3-15IML05:~$ docker exec -it SQL-MASTER bash 
root@0fbac997549d:/# docker exec -it SQL-MASTER bash 
bash: docker: command not found
root@0fbac997549d:/# mariadb -u root -psomewordpress
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 11.2.2-MariaDB-1:11.2.2+maria~ubu2204-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE USER 'replication_user'@'%' IDENTIFIED BY 'bigs3cret';
Query OK, 0 rows affected (0.011 sec)

MariaDB [(none)]> GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
Query OK, 0 rows affected (0.010 sec)

MariaDB [(none)]> SHOW MASTER STATUS;
+-------------------+----------+--------------+------------------+
| File              | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+-------------------+----------+--------------+------------------+
| mysqld-bin.000002 |      685 |              |                  |
+-------------------+----------+--------------+------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> UNLOCK TABLES;
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> exit;
Bye
root@0fbac997549d:/# exit 
exit
yans@yans-IdeaPad-3-15IML05:~$ docker ps 
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                                                                  NAMES
71ac447dd842   yanseg/worms   "/usr/local/bin/entr…"   29 minutes ago   Up 29 minutes   0.0.0.0:8081->80/tcp, :::8081->80/tcp, 0.0.0.0:19998->19999/tcp, :::19998->19999/tcp   WORDPRESS
87cf7c948a50   mariadb        "docker-entrypoint.s…"   29 minutes ago   Up 29 minutes   3306/tcp                                                                               SQL-SLAVE01
0fbac997549d   mariadb        "docker-entrypoint.s…"   29 minutes ago   Up 29 minutes   3306/tcp                                                                               SQL-MASTER
yans@yans-IdeaPad-3-15IML05:~$ docker exec -it SQL-MASTER bash 
root@0fbac997549d:/# exit 
exit
yans@yans-IdeaPad-3-15IML05:~$ docker exec -it SQL-SLAVE01 bash 
root@87cf7c948a50:/# mariadb -u root -psomewordpress
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 11.2.2-MariaDB-1:11.2.2+maria~ubu2204-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CHANGE MASTER TO
    ->   MASTER_HOST='172.21.0.3',
    ->   MASTER_USER='replication_user',
    ->   MASTER_PASSWORD='bigs3cret',
    ->   MASTER_PORT=3306,
    ->   MASTER_LOG_FILE='mysqld-bin.000002',
    ->   MASTER_LOG_POS=685,
    ->   MASTER_CONNECT_RETRY=10;
Query OK, 0 rows affected, 1 warning (0.062 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> SHOW SLAVE STATUS \G;
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 172.21.0.3
                   Master_User: replication_user
                   Master_Port: 3306
                 Connect_Retry: 10
               Master_Log_File: mysqld-bin.000002
           Read_Master_Log_Pos: 685
                Relay_Log_File: mysqld-relay-bin.000002
                 Relay_Log_Pos: 556
         Relay_Master_Log_File: mysqld-bin.000002
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
          Replicate_Rewrite_DB: 
               Replicate_Do_DB: 
           Replicate_Ignore_DB: 
            Replicate_Do_Table: 
        Replicate_Ignore_Table: 
       Replicate_Wild_Do_Table: 
   Replicate_Wild_Ignore_Table: 
                    Last_Errno: 0
                    Last_Error: 
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 685
               Relay_Log_Space: 866
               Until_Condition: None
                Until_Log_File: 
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File: 
            Master_SSL_CA_Path: 
               Master_SSL_Cert: 
             Master_SSL_Cipher: 
                Master_SSL_Key: 
         Seconds_Behind_Master: 0
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error: 
                Last_SQL_Errno: 0
                Last_SQL_Error: 
   Replicate_Ignore_Server_Ids: 
              Master_Server_Id: 1
                Master_SSL_Crl: 
            Master_SSL_Crlpath: 
                    Using_Gtid: No
                   Gtid_IO_Pos: 
       Replicate_Do_Domain_Ids: 
   Replicate_Ignore_Domain_Ids: 
                 Parallel_Mode: optimistic
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
              Slave_DDL_Groups: 0
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.001 sec)

ERROR: No query specified

MariaDB [(none)]> exit;
Bye
root@87cf7c948a50:/# 
```


## 5 / Vérification 

## 1 Installer wordpress, s'y connecter créer un post 
- Je récupère l'IP du container wordpress
``` 
./ipContainer.sh WORDPRESS
```
L'adresse IP du conteneur 'WORDPRESS' est : 172.21.0.4

- Puis je me rend dans mon browser
http://172.21.0.4/wp-admin/install.php

- J'install wordpress et je créé un post.



## 2 Vérification sur le SLAVE 

En se reconnectant au conatiner SQL-SLAVE01 je vérifie qu'un post s'est ahouté dans la table dédiée. 

```
yans@yans-IdeaPad-3-15IML05:~$ docker exec -it SQL-SLAVE01 bash 

root@87cf7c948a50:/# mariadb -u root -psomewordpress
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 12
Server version: 11.2.2-MariaDB-1:11.2.2+maria~ubu2204-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| wordpress          |
+--------------------+
5 rows in set (0.001 sec)

MariaDB [(none)]> use wordrpress;
ERROR 1049 (42000): Unknown database 'wordrpress'
MariaDB [(none)]> use wordpress;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [wordpress]> show tables;
+-----------------------+
| Tables_in_wordpress   |
+-----------------------+
| wp_commentmeta        |
| wp_comments           |
| wp_links              |
| wp_options            |
| wp_postmeta           |
| wp_posts              |
| wp_term_relationships |
| wp_term_taxonomy      |
| wp_termmeta           |
| wp_terms              |
| wp_usermeta           |
| wp_users              |
+-----------------------+
12 rows in set (0.001 sec)

MariaDB [wordpress]> select * from wp_posts;
```


## 3 On stop le SLAVE et on recré un autre post

```
 docker stop SQL-SLAVE01
```
- Je me rend sur mon wordpress dans mon browser, je recré un nouveau post.

- Je redémarre mon SLAVE : 
```
docker compose up à nouveau 
```
- Je me rend dans mon slave
```
docker exec -it SQL-SLAVE01 bash
```
- Je rend dans mariaDB et je vérifie bien que le nvx post que j'ai créé est dans la bdd du slave 
```
yans@yans-IdeaPad-3-15IML05:~$ docker exec -it SQL-SLAVE01 bash 
root@87cf7c948a50:/# mariadb -u root -psomewordpress
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 12
Server version: 11.2.2-MariaDB-1:11.2.2+maria~ubu2204-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| wordpress          |
+--------------------+
5 rows in set (0.001 sec)


MariaDB [(none)]> use wordpress;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [wordpress]> show tables;
+-----------------------+
| Tables_in_wordpress   |
+-----------------------+
| wp_commentmeta        |
| wp_comments           |
| wp_links              |
| wp_options            |
| wp_postmeta           |
| wp_posts              |
| wp_term_relationships |
| wp_term_taxonomy      |
| wp_termmeta           |
| wp_terms              |
| wp_usermeta           |
| wp_users              |
+-----------------------+
12 rows in set (0.001 sec)

MariaDB [wordpress]> select * from wp_posts;
```




### docker compose down pour fermer tous les conatiners 