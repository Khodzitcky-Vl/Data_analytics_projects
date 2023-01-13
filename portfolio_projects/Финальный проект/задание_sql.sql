/*
Образовательные курсы состоят из различных уроков, каждый из которых состоит из нескольких маленьких заданий. Каждое такое маленькое задание называется "горошиной".

Назовём очень усердным учеником того пользователя, который хотя бы раз за текущий месяц правильно решил 20 горошин. 
*/

WITH (SELECT toStartOfMonth(now())) AS current_month

WITH total_corr (st_id,  corr_peases) AS 
    (
        SELECT st_id, COUNT(timest)
        FROM default.peas
        WHERE correct = 1 AND toStartOfMonth(timest) = current_month
        GROUP BY st_id
    )

SELECT COUNT(st_id) FROM total_corr WHERE corr_peases >= 20 

/* 
Образовательная платформа предлагает пройти студентам курсы по модели trial: студент может решить бесплатно лишь 30 горошин в день. Для неограниченного количества заданий в определенной дисциплине студенту необходимо приобрести полный доступ. 
Команда провела эксперимент, где был протестирован новый экран оплаты.

Необходимо в одном запросе выгрузить следующую информацию о группах пользователей:

ARPU 
ARPAU 
CR в покупку 
СR активного пользователя в покупку 
CR пользователя из активности по математике (subject = ’math’) в покупку курса по математике
ARPU считается относительно всех пользователей, попавших в группы.

Активным считается пользователь, за все время решивший больше 10 задач правильно в любых дисциплинах.

Активным по математике считается пользователь, за все время решивший 2 или больше задач правильно по математике.
*/




WITH total_corr (st_id,  corr_peases) AS 
    (
        SELECT st_id, COUNT(timest)
        FROM default.peas
        WHERE correct = 1 
        GROUP BY st_id
    ), 

math_corr (st_id,  corr_peases_math) AS 
    (
        SELECT st_id, COUNT(timest)
        FROM default.peas
        WHERE correct = 1 AND subject = 'math'
        GROUP BY st_id
    ), 

full_table AS 
    (
        SELECT * 
        FROM default.studs 
        LEFT JOIN default.peas USING(st_id), 
        LEFT JOIN total_corr USING(st_id),
        LEFT JOIN math_corr USING(st_id), 
        JOIN default.final_project_check USING(st_id)
    )

SELECT 
    test_grp, 
    SUM(money) / uniqExact(st_id) AS ARPU, 
    sumIf(money, corr_peases > 10) / uniqExactIf(st_id, corr_peases > 10) AS ARPAU,
    uniqExactIf(st_id, sale_time IS NOT NULL) / uniqExact(st_id) AS CR,
    uniqExactIf(st_id, sale_time IS NOT NULL AND corr_peases > 10) / uniqExactIf(st_id, corr_peases > 10) AS CR_active, 
    uniqExactIf(st_id, sale_time IS NOT NULL AND corr_peases_math >= 2 AND default.final_project_check.subject = 'math') / uniqExactIf(st_id, corr_peases_math >= 2) AS CR_math
FROM full_table
GROUP BY 1

    

