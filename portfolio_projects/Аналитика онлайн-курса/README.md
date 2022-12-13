![elearning](https://user-images.githubusercontent.com/102512648/205432310-642fe591-91e9-43f5-8bb5-8c90cef78b25.png)

## Описание проекта

В этом проекта мы симулируем проведение учебной аналитики онлайн-курса с целью понимания и оптимизации учебного процесса и  среды, где этот процесс происходит.
Мы будем писать сложные SQL запросы на выборку из базы данных, которая состоит из 7 таблиц, связанных между собой по разными ключами (cхема представлена ниже).  
Проект выполнен в рамках прохождения онлайн-курса ['Интерактивный тренажер по SQL'](https://stepik.org/course/63054/info) на платформе Stepic.

## Навыки 

Базовый синтаксис SQL, сложные запросы SQL, оконные ф-ции, табличные выражения, UNION, работа с переменными

## Описание данных

**Логическая схема базы данных:**

![Логическая схема базы данных](https://user-images.githubusercontent.com/102512648/205432131-1c063477-b38e-4953-864b-ea39bdd7fc1e.png)


**Структура и частичное наполнение таблиц:**

Таблица `module`:

![module](https://user-images.githubusercontent.com/102512648/205431912-c3e029d9-f039-4bbc-a3f7-353c3616eee7.png)

Таблица `lesson` (в последнем столбце указан порядковый номер урока внутри модуля):

![lesson](https://user-images.githubusercontent.com/102512648/205431937-e6b3a476-900f-4a24-9c08-16b1906a3d81.png)

Таблица `step`:

![step](https://user-images.githubusercontent.com/102512648/205431956-a979eabd-c549-495b-a59a-631e561f5e9a.png)

Таблица `keyword`:

![keyword](https://user-images.githubusercontent.com/102512648/205431970-5f15adf0-52f3-4815-82d1-5badd62bd142.png)

Таблица `step_keyword`:

![step_keyword](https://user-images.githubusercontent.com/102512648/205431987-7eef7edb-8768-4d8f-9a3c-27a13d2c171a.png)

Таблица `student`:

![student](https://user-images.githubusercontent.com/102512648/205432005-1a6f8ed2-3bec-4924-84ac-0999a08add98.png)

 Таблица `step_student`  (в этой таблице хранятся все попытки пользователей по каждому шагу, указывается время начала попытки и время отправки задания на проверку, а также верный или неверный получился результат):

![step_student](https://user-images.githubusercontent.com/102512648/205432049-6669c943-6341-4b41-a076-90a770b8938f.png)
