use pizza_runner;

#1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH a as (
SELECT WEEK(registration_date) as weeks FROM runners)
SELECT a.*, COUNT(weeks) as num_each_week FROM a
GROUP BY weeks;

#2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH a as
(SELECT co.order_id, co.order_time, ro.pickup_time, CASE
WHEN (DAY(co.order_time) = DAY(ro.pickup_time)) THEN (MINUTE(ro.pickup_time))-(MINUTE(co.order_time))
WHEN (DAY(co.order_time) < DAY(ro.pickup_time)) THEN ((60 - (MINUTE(co.order_time))) + (MINUTE(ro.pickup_time))) 
ELSE null END as dur
 FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
HAVING dur IS NOT NULL)
SELECT AVG(a.dur) as avg_minute FROM a;

#3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH a as 
(SELECT co.order_id, co.order_time, ro.pickup_time, CASE
WHEN (DAY(co.order_time) = DAY(ro.pickup_time)) THEN (MINUTE(ro.pickup_time))-(MINUTE(co.order_time))
WHEN (DAY(co.order_time) < DAY(ro.pickup_time)) THEN ((60 - (MINUTE(co.order_time))) + (MINUTE(ro.pickup_time))) 
ELSE null END as dur
 FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
HAVING dur IS NOT NULL)
SELECT order_id, COUNT(order_id) as num_order, dur as duration FROM a
GROUP BY order_time ORDER BY num_order DESC;

#4 What was the average distance travelled for each customer?
WITH a as
(SELECT co.customer_id, ro.distance, CASE
WHEN SUBSTRING(ro.distance, 1, 4) > 0 THEN FORMAT(SUBSTRING(ro.distance, 1, 4) / 1, 2)  END as distance_new 
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id)
SELECT customer_id, FORMAT(AVG(distance_new), 2) as avg_distance_km FROM a
GROUP BY customer_id;

#5 What was the difference between the longest and shortest delivery times for all orders?
WITH a as
(SELECT co.order_id, co.order_time, ro.pickup_time, ro.duration,
SUBSTRING(duration, 1, 2) as num
 FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
HAVING ro.pickup_time NOT LIKE '%null%' AND ro.pickup_time IS NOT NULL)
SELECT MAX(num) as longest, MIN(num) as shortest, CASE
WHEN MAX(num) > MIN(num) THEN MAX(num) - MIN(num)
ELSE 0 END as difference_minutes FROM a;

#6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH a as
(SELECT co.customer_id, co.order_id, ro.runner_id, ro.distance, ro.duration, CASE
WHEN SUBSTRING(ro.distance, 1, 4) > 0 THEN FORMAT(SUBSTRING(ro.distance, 1, 4)/SUBSTRING(ro.duration, 1, 2) , 2) 
ELSE 0 END as speed FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE pickup_time > 0)
SELECT a.runner_id, a.order_id, COUNT(a.runner_id) as volume, FORMAT(AVG(speed), 2) as avg_speed_kmper_minute FROM a
GROUP BY a.runner_id, a.order_id
ORDER BY runner_id;
# from the result, we can see the trend that for each runner, the trend of the speed average to deliver the order is down. 
#The earlier customer order, the more less average of the speed.

#7 What is the successful delivery percentage for each runner?
WITH c as (WITH b as (WITH a as
(SELECT ro.runner_id, CASE 
WHEN ro.pickup_time > 0 THEN 1 ELSE 0 END as suc, COUNT(co.order_id) as num_order
FROM customer_orders co JOIN runner_orders ro
ON co.order_id = ro.order_id
GROUP BY ro.runner_id, suc
ORDER BY ro.runner_id)
SELECT a.*, a1.runner_id as run1, a1.suc as succ, a1.num_order as nor FROM a INNER JOIN a a1
ON a.runner_id = a1.runner_id)
SELECT *, CASE WHEN suc = succ THEN 0 ELSE runner_id END as uy FROM b)
SELECT *, CASE WHEN (runner_id IN (SELECT DISTINCT(uy) FROM c)) AND suc != succ THEN FORMAT((num_order/(num_order+nor))*100, 2)
WHEN runner_id NOT IN (SELECT DISTINCT(uy) FROM c) THEN FORMAT((num_order/num_order)*100, 2)
ELSE 0 END as percentage 
FROM c WHERE suc = 1
HAVING percentage > 0;