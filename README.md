#  Дипломная работа по профессии «Системный администратор» - Денис Костюк

Содержание
==========
* [Введение](#Введение)
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------
## Введение
Как это все работает:  
На сервисе Yandex Cloud создана виртуальная машина, на которой установлены Terreform и Ansible, а также размещены файлы проекта для развертывания инфраструктуры из дипломного задания. Эта виртуальная машина работает постоянно и непрерывно, поэтому доступ к ней есть всегда. Дипломный руководитель при проверке дипломного задания может командой terraform destroy удалить инфраструктуру, а командой terraform apply запустить создание инфраструктуры "с нуля".
Доступ к виртуальной машине, с которой разворачивается инфраструктура из дипломного задания:  
ip = 51.250.69.216  
user = diplom-kostyuk  
pass = пароль в целях безопасности отправлен в сопроводительном сообщении к ссылке на результат дипломной работы.  
Интерфейс командной строки Yandex Cloud (CLI) подключен.  
  
Разворачивание инфраструктуры полностью автоматизировано, включая настройку конфигурационных файлов. Руками надо настраивать только ту часть, которая настраивается через WEB-интерфейс, а именно: Kibana и Zabbix.  
Пароль от БД Zabbix = 123456  
IP-адреса хостов (как внутренние, так и внешние) выводятся в аутпутах по результатам отработки проекта.  

Итак, подключаемся к серверу с проектом по учетным данным, приведенным выше:  
![0-1](./pics/0-1.png)

Далее идем в директорию diplom и запускаем команду terraform apply:
![0-2](./pics/0-2.png)
  
Далее yes:  
![0-3](./pics/0-3.png)
  
Через какое-то время проект отработает, на выходе в аутпутах получаем IP-адреса созданных хостов:  
![0-4](./pics/0-4.png)
  
Подключаться к серверам можно по внутренним IP через бастион пользователем user. Например, для подключения к WM-1 (виртуальная машина №1) можно испоьзовать команду: ssh -i ~/.ssh/id_rsa -J user@158.160.100.15 user@192.168.1.4, где "158.160.100.15" - это внешний IP-адрес бастиона, а "192.168.1.4" - это внутренний адрес хоста, к которому надо подключиться.  

Далее настраиваем Kibana и Zabbix через вэб-интерфейс.  

Теперь переходим к демонстрации непосредственно дипломной работы:  

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git.  

## Инфраструктура
  
Инфраструктура разворачивается с помощью Terraform и Ansible.  
Инвентори-файл hosts.txt для Ansible создается автоматически и использует fqdn имена виртуальных машин:  
![1-01](./pics/1-01.png)
![1-2](./pics/1-2.png)

## Сайт

Проверяем работу балансера:  
![2-1](./pics/2-1.png)

в том числе через вэб-интерфейс:  
![2-2](./pics/2-2.png)  
![2-3](./pics/2-3.png)  

По внешним IP сайты vm-1 с vm-2 недоступны.  
  
Балансировщик:  
![2-4](./pics/2-4.png)   

   
![2-5](./pics/2-5.png)   

## Мониторинг
  
По умолчанию имя пользователя - Admin, пароль — zabbix.  
![3-1](./pics/3-1.png) 
