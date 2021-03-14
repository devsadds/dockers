# docker-mssql

**Требования:**

 - docker;
 - docker-compose;
 - linux.


**Собираем образ**

```
docker-compose build
```

**Далее правим docker-compose.yml***

Приводим к необходимому виду - правим пароль - он дожден соостветвовать требованиям надежности мелкомягких - иначе не заведется.


**Запускаем**

```
docker-compose up -d
```

Заходим внутрь докер контейнерв

```
docker exec -ti -u 0 mssql-server-server sh -c 'stty cols 250 && stty rows 100 && bash'
```

**Восстановим дамп из бэкапа**

Иы пробросили каталог ./backups внутрь докер контейнера в каталог /backups.

Восстановим дамп из файла(например) GRN_MAIN.bak

Для этого выполним sql - просмотрим инфу о файле.
```
docker exec -it mssql-server-server /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourStrong!Passw0rd' -Q "RESTORE FILELISTONLY  FROM DISK = '/backups/GRN_MAIN.bak'"
```
Нас интересует имя GRN_MAIN.mdf и его расположение, а также имя GRN_MAIN_1.ldf и его расположение.

Теперь произведем восстановление из дампа

Из консоли
```
docker exec -it mssql-server-server /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourStrong!Passw0rd' -Q " RESTORE DATABASE GRN_MAIN FROM DISK = '/backups/GRN_MAIN.bak' WITH MOVE 'GRN_MAIN_Data' TO '/var/opt/mssql/data/GRN_MAIN.mdf', MOVE 'GRN_MAIN_Log' TO '/var/opt/mssql/data/GRN_MAIN_1.ldf'"
```
Ждем окончания.

Или из GUI для mssql - например - DBEAVER

```

RESTORE DATABASE GRN_MAIN
FROM DISK = '/var/opt/mssql/backup/GRN_MAIN.bak'
WITH MOVE 'GRN_MAIN_Data' TO '/var/opt/mssql/data/GRN_MAIN.mdf',
MOVE 'GRN_MAIN_Log' TO '/var/opt/mssql/data/GRN_MAIN_1.ldf'
GO
```

#Сделать бэкап
```
docker exec -it mssql-server-server /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'YourStrong!Passw0rd' -Q "BACKUP DATABASE [GRN_MAIN] TO DISK = N'/backups/GRN_MAIN_backup.bak' WITH NOFORMAT, NOINIT, NAME = 'GRN_MAIN-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
```


#Проверьте версию контейнера
```
docker exec -it mssql-server-server /opt/mssql-tools/bin/sqlcmd \
   -S localhost -U SA -P 'YourStrong!Passw0rd' \
   -Q 'SELECT @@VERSION'
```