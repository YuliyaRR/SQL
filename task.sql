-- 1) Вывести к каждому самолету класс обслуживания и количество мест этого класса

---1 вариант с выводом модели самолета

SELECT model, aircraft_code, 
COUNT(seats) Filter(WHERE fare_conditions = 'Business') as business_seats,
COUNT(seats) Filter(WHERE fare_conditions = 'Economy') as economy_seats,
COUNT(seats) Filter(WHERE fare_conditions = 'Comfort') as comfort_seats
FROM aircrafts_data
JOIN seats
USING (aircraft_code)
GROUP BY aircraft_code, model

---2 вариант без вывода модели, тогда можно без join

SELECT aircraft_code, 
COUNT(seats) Filter(WHERE fare_conditions = 'Business') as business_seats,
COUNT(seats) Filter(WHERE fare_conditions = 'Economy') as economy_seats,
COUNT(seats) Filter(WHERE fare_conditions = 'Comfort') as comfort_seats
FROM seats
GROUP BY aircraft_code


-- 2) Найти 3 самых вместительных самолета (модель + кол-во мест) 

SELECT model, COUNT(seat_no) as seats_amount
FROM aircrafts_data
JOIN seats
USING (aircraft_code)
GROUP BY aircraft_code 
ORDER by seats_amount DESC
LIMIT 3


-- 3) Вывести код, модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

SELECT aircraft_code, model, seat_no
FROM aircrafts_data
JOIN seats USING (aircraft_code)
WHERE model ->> 'ru' LIKE '%Аэробус A321-200%'
AND fare_conditions != 'Economy'
ORDER BY seat_no;


-- 4) Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)

--- 1 вариант с вложенным подзапросом

SELECT airport_code, airport_name, city
FROM airports_data
WHERE city IN (SELECT city
			   FROM airports_data
			   GROUP BY city
			   HAVING COUNT (airport_code) > 1)
	
--- 2 вариант с использованием CTE (Common Table Expression)

With tmp as (SELECT city
			 FROM airports_data
			 GROUP BY city
			 HAVING COUNT (airport_code) > 1)

SELECT airport_code, airport_name, city
FROM tmp
JOIN airports_data USING (city)
WHERE city IN (tmp.city)


-- 5) Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

WITH tmp_dep as (SELECT airport_code 
				 FROM bookings.airports_data
				 WHERE city ->> 'ru' = 'Екатеринбург'), 
	
	tmp_arr as (SELECT airport_code 
				FROM bookings.airports_data
				WHERE city ->> 'ru' = 'Москва')

SELECT flight_id, flight_no, scheduled_departure, departure_airport, arrival_airport, status 
FROM tmp_dep
JOIN flights ON tmp_dep.airport_code = flights.departure_airport
JOIN tmp_arr ON tmp_arr.airport_code = flights.arrival_airport 
WHERE status = 'On Time'
ORDER BY scheduled_departure ASC
LIMIT 1


-- 6) Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)

--- 1 вариант с выводом всех билетов с минимальной и максимальной ценой

WITH tmp_max AS (SELECT ticket_no, amount as amount_max 
				 FROM ticket_flights
				 WHERE amount = (SELECT MAX(amount)FROM ticket_flights)
				 GROUP BY ticket_no, amount),
	 tmp_min AS (SELECT ticket_no, amount as amount_min 
				 FROM ticket_flights
				 WHERE amount = (SELECT MIN(amount) FROM ticket_flights)
				 GROUP BY ticket_no, amount)

SELECT ticket_no, NULL as amount_max, amount_min
FROM tmp_min
UNION
SELECT ticket_no, amount_max, NULL as amount_min
FROM tmp_max
ORDER BY amount_min;

--- 2 вариант с выводом 1 билета с минимальной и 1 билета с максимальной ценой 

WITH tmp_max AS (SELECT ticket_no, amount as amount_max 
				 FROM ticket_flights
				 WHERE amount = (SELECT MAX(amount)FROM ticket_flights)
				 GROUP BY ticket_no, amount
				 LIMIT 1),
	 tmp_min AS (SELECT ticket_no, amount as amount_min 
				 FROM ticket_flights
				 WHERE amount = (SELECT MIN(amount) FROM ticket_flights)
				 GROUP BY ticket_no, amount
			     LIMIT 1)
				 
SELECT ticket_no, NULL as amount_max, amount_min
FROM tmp_min
UNION
SELECT ticket_no, amount_max, NULL as amount_min
FROM tmp_max
ORDER BY amount_min; 


-- 7) Вывести информацию о вылете с наибольшей суммарной стоимостью билетов

--- 1 вариант с выводом подробной информации о рейсе

WITH total AS (SELECT flight_id, SUM(amount) as total_price
			   FROM ticket_flights
			   GROUP BY flight_id)
		   

SELECT flight_id, total_price, flight_no, 
	scheduled_departure, scheduled_arrival, 
	departure_airport, arrival_airport, 
	status, aircraft_code, 
	actual_departure, actual_arrival
FROM (SELECT flight_id, total_price 
	  FROM total
	  WHERE total_price IN (SELECT MAX(total_price) FROM total)) inn
JOIN flights USING (flight_id)

--- 2 вариант без вывода подробной информации о рейсе с использованием вложенных запросов

SELECT flight_id, SUM(amount) as total_price
FROM ticket_flights
JOIN flights USING (flight_id)
GROUP BY flight_id
HAVING SUM(amount) = (SELECT MAX(total_price) AS max_price
					  FROM (SELECT flight_id, SUM(amount) as total_price
							FROM ticket_flights
							GROUP BY flight_id) inn)


-- 8) Найти модель самолета, принесшую наибольшую прибыль (наибольшая суммарная стоимость билетов). Вывести код модели, информацию о модели и общую стоимость

--- 1 вариант с использованием вложенных подзапросов, обратной сортировкой по суммарной стоимости и лимитом вывода в 1 элемент (он же будет максимальным элементом)

SELECT aircraft_code, model, range, SUM(amount) as total_price
FROM aircrafts_data
JOIN flights USING (aircraft_code)
JOIN ticket_flights USING (flight_id)
GROUP BY aircraft_code
ORDER BY total_price DESC
LIMIT 1

--- 2 вариант с использованием временной таблицы

WITH total AS (SELECT aircraft_code, SUM(amount) as total_price
			   FROM ticket_flights
			   JOIN flights USING (flight_id)
			   GROUP BY aircraft_code)

SELECT aircraft_code, model, range, total_price
FROM total 
JOIN aircrafts USING (aircraft_code)
WHERE total_price = (SELECT MAX(total_price) FROM total)


-- 9) Найти самый частый аэропорт назначения для каждой модели самолета. Вывести количество вылетов, информацию о модели самолета, аэропорт назначения, город

WITH tmp AS (SELECT aircraft_code, arrival_airport, COUNT(arrival_airport) as arrival_count
			 FROM flights
			 GROUP BY aircraft_code, arrival_airport),
	 res AS (SELECT aircraft_code, MAX(arrival_count) as arr_count
			 FROM tmp
			 GROUP BY aircraft_code)

SELECT aircraft_code, model, range, arrival_airport, city, arrival_count
FROM tmp
JOIN res USING (aircraft_code)
JOIN aircrafts_data USING (aircraft_code)
JOIN airports_data ON tmp.arrival_airport = airports_data.airport_code
WHERE arrival_count = res.arr_count

