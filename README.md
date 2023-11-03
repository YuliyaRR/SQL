# SQL
*Postgresql (including training DB) | Docker | pgAdmin*

В данном репозитории размещена учебная база Postgresql, поднятая в Docker, и комплекс решенных заданий на отработку запросов по выборке данных. 

Доступно подключение через pgAdmin.

## Порядок запуска
1. Установить docker и docker-compose;
2. Склонировать репозиторий командой 
```
   git clone https://github.com/YuliyaRR/SQL.git
```
3. В локальном репозитории выполнить команду
```
  docker-compose up -d
```
4. После выполнения команды выше в docker будет поднята база данных и pgAdmin
5. Описание предметной области базы данных находится в файле [demo.pdf](https://github.com/YuliyaRR/SQL/blob/master/demo.pdf)
6. Описание выполненных запросов находится в файле [task.sql](https://github.com/YuliyaRR/SQL/blob/master/task.sql) 

### Подключение через поднятый в docker pgAdmin
1. pgAdmin доступен по адресу localhost:5050
2. После установки master-пароля создать сервер:
    - name: postgres (можно любое)
    - host: postgres
    - port: 5432
    - maintenance database: postgres
    - username: postgres
    - password: postgres
4. Таблицы расположены в схеме bookings
