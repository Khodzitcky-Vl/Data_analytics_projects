/*
Для каждого шага вывести процент правильных решений. Информацию отсортировать сначала по возрастанию успешности, а затем по названию шага в алфавитном порядке.
Столбцы результата назвать Шаг и Успешность, процент успешных решений округлить до целого.
*/

WITH get_count_correct (st_n_c, count_correct) AS 
   (
    SELECT step_name, count(*)
    FROM 
        step 
        INNER JOIN step_student USING (step_id)
    WHERE result = "correct"
    GROUP BY step_name
   ),
get_count_wrong (st_n_w, count_wrong) AS 
   (
    SELECT step_name, count(*)
    FROM 
        step 
        INNER JOIN step_student USING (step_id)
    WHERE result = "wrong"
    GROUP BY step_name
   )  
   
SELECT st_n_c AS Шаг,
    IFNULL(ROUND(count_correct / (count_correct + count_wrong) * 100), 100) AS Успешность
FROM  
    get_count_correct 
    LEFT JOIN get_count_wrong ON st_n_c = st_n_w
    
UNION

SELECT st_n_w AS Шаг,
    IFNULL(ROUND(count_correct / (count_correct + count_wrong) * 100), 0) AS Успешность
FROM  
    get_count_correct 
    RIGHT JOIN get_count_wrong ON st_n_c = st_n_w
ORDER BY 2, 1

/* 
Вычислить прогресс пользователей по курсу. Прогресс вычисляется как отношение верно пройденных шагов к общему количеству шагов в процентах, округленное до целого. 
В нашей базе данные о решениях занесены не для всех шагов, поэтому общее количество шагов определить как количество различных шагов в таблице step_student.

Тем пользователям, которые прошли все шаги (прогресс = 100%) выдать "Сертификат с отличием". Тем, у кого прогресс больше или равен 80% - "Сертификат". Для остальных записей в столбце Результат задать пустую строку (""). 
*/

SET @all_steps = (SELECT COUNT(DISTINCT step_id) FROM step_student);

WITH t_1 (student_id, progress) AS 
    (
     SELECT 
        student_id, 
        ROUND(COUNT(DISTINCT step_id) / @all_steps * 100, 0)
     FROM step_student 
     WHERE result = 'correct'
     GROUP BY student_id
    )

SELECT 
    student_name AS Студент, 
    progress AS Прогресс, 
    CASE 
        WHEN progress = 100 THEN "Сертификат с отличием"
        WHEN progress >= 80 THEN "Сертификат"
        ELSE ''
    END AS Результат
FROM t_1 JOIN student USING(student_id)
ORDER BY Прогресс DESC, student_name

/* 
Для студента с именем student_61 вывести все его попытки: название шага, результат и дату отправки попытки (submission_time). Информацию отсортировать по дате отправки попытки и указать, сколько минут прошло между отправкой соседних попыток. 
Название шага ограничить 20 символами и добавить "...". Столбцы назвать Студент, Шаг, Результат, Дата_отправки, Разница. 
*/

SELECT
    student_name AS Студент, 
    CONCAT(LEFT(step_name, 20), '...') AS Шаг, 
    result AS Результат, 
    FROM_UNIXTIME(submission_time) AS Дата_отправки, 
    SEC_TO_TIME(submission_time - LAG(submission_time, 1, submission_time) OVER(ORDER BY submission_time)) AS Разница
FROM
    step
    JOIN step_student USING(step_id)
    JOIN student USING(student_id)
WHERE student_name = 'student_61'
ORDER BY Дата_отправки

/* 
Посчитать среднее время, за которое пользователи проходят урок по следующему алгоритму:

- для каждого пользователя вычислить время прохождения шага как сумму времени, потраченного на каждую попытку (время попытки - это разница между временем отправки задания и временем начала попытки), 
при этом попытки, которые длились больше 4 часов не учитывать, так как пользователь мог просто оставить задание открытым в браузере, а вернуться к нему на следующий день;
- для каждого студента посчитать общее время, которое он затратил на каждый урок;
- вычислить среднее время выполнения урока в часах, результат округлить до 2-х знаков после запятой;
- вывести информацию по возрастанию времени, пронумеровав строки, для каждого урока указать номер модуля и его позицию в нем. 
*/

SELECT 
    ROW_NUMBER() OVER(ORDER BY AVG(lesson_time)) AS Номер, 
    lesson_name AS Урок, 
    AVG(lesson_time) AS Среднее_время
FROM
    (SELECT
        student_id, lesson_name,
        SUM(step_time)/3600 AS lesson_time
    FROM
        (SELECT 
            student_id, step_id,
            SUM(submission_time - attempt_time) AS step_time 
         FROM step_student
         WHERE submission_time - attempt_time < (4*60*60)
         GROUP BY student_id, step_id
        ) AS q_1 
        JOIN step USING(step_id)
        JOIN lesson USING(lesson_id)
    GROUP BY student_id, lesson_name
    ) AS q_2 
GROUP BY lesson_name
ORDER BY Среднее_время

/* 
Вычислить рейтинг каждого студента относительно студента, прошедшего наибольшее количество шагов в модуле (вычисляется как отношение количества пройденных студентом шагов к максимальному количеству пройденных шагов, умноженное на 100). 
Вывести номер модуля, имя студента, количество пройденных им шагов и относительный рейтинг. Относительный рейтинг округлить до одного знака после запятой. Столбцы назвать Модуль, Студент, Пройдено_шагов и Относительный_рейтинг  соответственно. 
Информацию отсортировать сначала по возрастанию номера модуля, потом по убыванию относительного рейтинга и, наконец, по имени студента в алфавитном порядке. 
*/

WITH t_1 (module, id, count_steps) AS 
(
    SELECT 
        module_id, 
        student_id,
        COUNT(DISTINCT step_id)
    FROM 
        step_student 
        JOIN step USING(step_id)
        JOIN lesson USING(lesson_id)
    WHERE result = 'correct'
    GROUP BY module_id, student_id
), 
t_2 (module_id, max_steps) AS 
(
    SELECT 
        module, 
        MAX(count_steps)
    FROM t_1
    GROUP BY module
)
        
SELECT 
    module_id AS Модуль, 
    student_name AS Студент, 
    COUNT(DISTINCT step_id) AS Пройдено_шагов, 
    ROUND(COUNT(DISTINCT step_id)/max_steps*100, 1) AS Относительный_рейтинг
FROM student 
    INNER JOIN step_student USING(student_id)
    INNER JOIN step USING (step_id)
    INNER JOIN lesson USING (lesson_id)
    INNER JOIN t_2 USING(module_id)
WHERE result = 'correct'
GROUP BY module_id, student_name
ORDER BY module_id, Относительный_рейтинг DESC, student_name

/* 
Проанализировать, в каком порядке и с каким интервалом пользователь отправлял последнее верно выполненное задание каждого урока. В базе занесены попытки студентов  для трех уроков курса, поэтому анализ проводить только для этих уроков.

Для студентов прошедших как минимум по одному шагу в каждом уроке, найти последний пройденный шаг каждого урока - крайний шаг, и указать:

- имя студента;
- номер урока, состоящий из номера модуля и через точку позиции каждого урока в модуле;
- время отправки  - время подачи решения на проверку;
- разницу во времени отправки между текущим и предыдущим крайним шагом в днях, при этом для первого шага поставить прочерк ("-"), а количество дней округлить до целого в большую сторону.

толбцы назвать  Студент, Урок,  Макс_время_отправки и Интервал  соответственно. Отсортировать результаты по имени студента в алфавитном порядке, а потом по возрастанию времени отправки. 
*/

WITH get_students_result(Студент, Урок, Макс_время_отправки) AS 
(
    SElECT 
        student_name, 
        CONCAT(module_id, '.', lesson_position), 
        MAX(submission_time)
    FROM student 
        INNER JOIN step_student USING(student_id)
        INNER JOIN step USING (step_id)
        INNER JOIN lesson USING (lesson_id)
    WHERE result = 'correct'
    GROUP BY 1, 2
), 
get_students_result3 AS 
(
    SELECT 
        Студент
    FROM get_students_result
    GROUP BY Студент
    HAVING COUNT(DISTINCT Урок) = 3
)

SELECT Студент, Урок, FROM_UNIXTIME(Макс_время_отправки) AS Макс_время_отправки,
    IFNULL(CEIL((Макс_время_отправки - LAG(Макс_время_отправки) OVER (PARTITION BY Студент ORDER BY Макс_время_отправки))/86400), '-') AS Интервал
FROM get_students_result3 JOIN get_students_result USING(Студент)
ORDER BY Студент, Макс_время_отправки 

/* 
Для студента с именем student_59 вывести следующую информацию по всем его попыткам:

- информация о шаге: номер модуля, символ '.', позиция урока в модуле, символ '.', позиция шага в модуле;
- порядковый номер попытки для каждого шага - определяется по возрастанию времени отправки попытки;
- результат попытки;
- время попытки (преобразованное к формату времени) - определяется как разность между временем отправки попытки и времени ее начала, в случае если попытка длилась более 1 часа, то время попытки заменить на среднее время всех попыток пользователя по всем шагам без учета тех, которые длились больше 1 часа;
- относительное время попытки  - определяется как отношение времени попытки (с учетом замены времени попытки) к суммарному времени всех попыток  шага, округленное до двух знаков после запятой  .

Столбцы назвать  Студент,  Шаг, Номер_попытки, Результат, Время_попытки и Относительное_время. Информацию отсортировать сначала по возрастанию id шага, а затем по возрастанию номера попытки (определяется по времени отправки попытки). 
*/

SET @avg_time = (SELECT ROUND(AVG(submission_time - attempt_time))
                 FROM student INNER JOIN step_student USING(student_id)
                 WHERE student_name = 'student_59' AND (submission_time - attempt_time) / 3600 < 1
                 GROUP BY student_name
                 ); 
                 
WITH cte_1 AS 
(
    SELECT
        step_student_id,
        step_id,
        CASE 
            WHEN (submission_time - attempt_time) / 3600 < 1 THEN (submission_time - attempt_time)
            ELSE @avg_time
        END AS Время_попытки
    FROM student INNER JOIN step_student USING(student_id) 
    WHERE student_name = 'student_59'
)
    
    SELECT
        student_name AS Студент,
        CONCAT(module_id, '.', lesson_position, '.', step_position) AS Шаг, 
        ROW_NUMBER() OVER(PARTITION BY step_student.step_id ORDER BY submission_time) AS               Номер_попытки,
        result AS Результат, 
        SEC_TO_TIME(Время_попытки) AS Время_попытки,
        ROUND(Время_попытки / SUM(Время_попытки) OVER (PARTITION BY cte_1.step_id)*100, 2) AS Относительное_время
    FROM student 
        INNER JOIN step_student USING(student_id)
        INNER JOIN step USING (step_id)
        INNER JOIN lesson USING (lesson_id)
        INNER JOIN cte_1 USING(step_student_id)
    WHERE student_name = 'student_59'

/* 
Online курс обучающиеся могут проходить по различным траекториям, проследить за которыми можно по способу решения ими заданий шагов курса. Большинство обучающихся за несколько попыток  получают правильный ответ 
и переходят к следующему шагу. Но есть такие, что остаются на шаге, выполняя несколько верных попыток, или переходят к следующему, оставив нерешенные шаги.

Выделив эти "необычные" действия обучающихся, можно проследить их траекторию работы с курсом и проанализировать задания, для которых эти действия выполнялись, а затем их как-то изменить. 

Для этой цели необходимо выделить группы обучающихся по способу прохождения шагов:

- I группа - это те пользователи, которые после верной попытки решения шага делают неверную (скорее всего для того, чтобы поэкспериментировать или проверить, как работают примеры);
- II группа - это те пользователи, которые делают больше одной верной попытки для одного шага (возможно, улучшают свое решение или пробуют другой вариант);
- III группа - это те пользователи, которые не смогли решить задание какого-то шага (у них все попытки по этому шагу - неверные).

Вывести группу (I, II, III), имя пользователя, количество шагов, которые пользователь выполнил по соответствующему способу. Столбцы назвать Группа, Студент, Количество_шагов. 
Отсортировать информацию по возрастанию номеров групп, потом по убыванию количества шагов и, наконец, по имени студента в алфавитном порядке. 
*/

SELECT 'I' AS Группа, student_name AS Студент, COUNT(step_id) AS Количество_шагов
FROM 
    (SELECT 
        student_name, step_id, result, 
        LAG(result) OVER (PARTITION BY student_name, step_id ORDER BY submission_time) AS prev_result
    FROM step_student JOIN student USING(student_id)
    ) AS t_1
WHERE result = 'wrong' AND prev_result = 'correct'
GROUP BY student_name

UNION

SELECT 'II' AS Группа, student_name AS Студент, COUNT(step_id) AS Количество_шагов
FROM 
    (SELECT student_name, step_id
    FROM step_student JOIN student USING(student_id)
    WHERE result = 'correct'
    GROUP BY student_name, step_id
    HAVING COUNT(result) >= 2
    ) AS t_2
GROUP BY student_name

UNION 

SELECT 'III' AS Группа, student_name AS Студент, COUNT(step_id) AS Количество_шагов
FROM 
    (SELECT student_name, step_id
    FROM step_student JOIN student USING(student_id)
    GROUP BY student_name, step_id
    HAVING SUM(CASE WHEN result = 'correct' THEN 1 ELSE 0 END) = 0 
    ) AS t_3
GROUP BY student_name

ORDER BY 1, 3 DESC, 2








