 /* У вас есть SQL база данных с таблицами международной частной клиники, которая существует много лет: 
1) Patients(patientId, age) 
2) Visits(visitId, patientId, serviceId, date) 
3) Services(serviceId, cost) 
Напишите четыре SQL запроса для расчета следующих метрик. 
В расчете учитывайте повышенную вероятность коллизий по агрегатам различных метрик, например, существует несколько услуг с одинаковой доходностью в промежутке времени. 

Вопрос 1: А) какую сумму в среднем в месяц тратит: - пациент в возрастном диапазоне от 18 до 25 лет включительно - пациент в возрастном диапазоне от 26 до 35 лет включительно  */  


SELECT  CASE WHEN p.age BETWEEN 18 AND 25 THEN '18-25'
             WHEN p.age BETWEEN 26 AND 35 THEN '26-35' END AS age_gr
       , AVG(revenue) AS avg_rev
FROM
(
	SELECT  p.patientld
	       , EXTRACT(YEAR FROM v.date) AS yr
           , EXTRACT(MONTH FROM v.date) AS mnth, SUM(s.cost) AS revenue
	FROM Patients AS p
	LEFT JOIN Visits AS v USING (patientld)
	LEFT JOIN Services AS s USING (serviceld)
	GROUP BY  p.patientld
	         ,yr
	         ,mnth
) all

JOIN Patients AS p USING (patientld)
GROUP BY  age_gr



/* Вопрос 2: Б) в каком месяце года доход от пациентов в возрастном диапазоне 35+ самый большой  */

SELECT EXTRACT(MOUTH FROM date) as mnth
        , SUM(cost) as revenue
FROM Visits
LEFT JOIN Services USING (servicesld)
WHERE patientld in (
                    SELECT partientld 
                    FROM PATIENTS 
                    WHERE age >= 35
                    )
GROUP BY mnth
ORDER BY revenue desc
LIMIT 1



/* Вопрос 3: В) какая услуга обеспечивает наибольший вклад в доход за последний год  */

SELECT v.(servicesld), SUM(cost) as revenue
FROM Visits as v
LEFT JOIN Services USING (servicesld)
WHERE EXTRACT(YEAR FROM date) = 2024
GROUP BY v.serviceld
ORDER BY revenue desc
LIMIT 1



/* Вопрос 4: Г) ежегодные топ-5 услуг по доходу и их доля в общем доходе за год  */

WITH t1 AS (
    SELECT EXTRACT(YEAR FROM date) as yr
            , v.serviceld
            , SUM(cost) as revenue
    FROM Visits as v
    LEFT JOIN Services USING (serviceld)
    GROUP BY yr, v.serviceld 
    ),

t2 AS (
    SELECT yr, SUM(revenue) AS total_rev
    FROM t1
    GROUP BY yr
    ),

t3 AS (
    SELECT yr, serviceld, revenue, ROW_NUMBER(PARTITION BY yr ORDER BY revenue DESC) as rank
    FROM t1
    )

SELECT t3.yr, t3.serviceld, t3.revenue, t3.revenue::decimal/t1.total_rev as share
FROM t3
LEFT JOIN t2 ON t3.yr = t2.yr
WHERE t3.rank <= 5
ORDER BY t3.yr, t3.rank