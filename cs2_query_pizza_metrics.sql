USE pizza_runner;

#PART A : PIZZA METRICS
#1 How many pizzas were ordered?
SELECT order_id, count(order_id) as num_pizza FROM customer_orders;

#2 How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) as unique_customer FROM customer_orders;

#3 How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) as succes_order FROM runner_orders
WHERE pickup_time NOT LIKE '%null%'
GROUP BY runner_id;

#4 How many of each type of pizza was delivered?
SELECT a.pizza_id, COUNT(a.pizza_id) as num_pizza FROM
(SELECT co.order_id, co.customer_id, co.pizza_id, co.order_time, ro.runner_id, ro.pickup_time, ro.cancellation,
CASE WHEN pickup_time = 'null' THEN 'N'
ELSE 'Y' END as yn
FROM customer_orders co JOIN runner_orders ro
ON co.order_id = ro.order_id) as a
WHERE a.yn = 'Y'
GROUP BY a.pizza_id;

#5 How many Vegetarian and Meatlovers were ordered by each customer?
SELECT a.pizza_name,COUNT(a.pizza_name) as num_pizza FROM
(SELECT co.order_id, co.customer_id, co.pizza_id, pn.pizza_name, co.order_time, ro.runner_id, ro.pickup_time, ro.cancellation,
CASE WHEN pickup_time = 'null' THEN 'N'
ELSE 'Y' END as yn
FROM customer_orders co JOIN runner_orders ro
ON co.order_id = ro.order_id
JOIN pizza_names pn ON
co.pizza_id = pn.pizza_id) as a
GROUP BY a.pizza_name;

#6 What was the maximum number of pizzas delivered in a single order?
with b as 
(SELECT a.order_time, COUNT(a.order_time) as num_order FROM
(SELECT co.order_id, co.customer_id, co.pizza_id, pn.pizza_name, co.order_time, ro.runner_id, ro.pickup_time, ro.cancellation,
CASE WHEN pickup_time = 'null' THEN 'N'
ELSE 'Y' END as yn
FROM customer_orders co JOIN runner_orders ro
ON co.order_id = ro.order_id
JOIN pizza_names pn ON
co.pizza_id = pn.pizza_id) as a
GROUP BY a.order_time)
SELECT order_time, MAX(num_order) as max_order FROM b;

#7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH b as
(WITH a as
(SELECT co.customer_id, ro.pickup_time, CASE
WHEN (exclusions IS NOT NULL AND exclusions NOT LIKE '%null%' AND exclusions > 0)  AND (extras IS NOT NULL AND extras NOT LIKE '%null%') AND (extras > 0) THEN 2
WHEN (exclusions IS NOT NULL AND exclusions NOT LIKE'%null%' AND exclusions > 0) OR (extras IS NOT NULL AND extras NOT LIKE '%null%' AND extras > 0) THEN 1
ELSE 0 END as changes
FROM customer_orders co
JOIN runner_orders ro
ON co.order_id = ro.order_id
HAVING ro.pickup_time NOT LIKE '%null%')
SELECT a.customer_id, CASE
WHEN a.changes = 0 THEN 'no changes' 
ELSE 'had changes' END as changes_cat FROM a)
SELECT b.customer_id, b.changes_cat, COUNT(b.changes_cat) as num_pizza FROM b
GROUP BY b.customer_id, b.changes_cat
ORDER BY customer_id;

#8 How many pizzas were delivered that had both exclusions and extras?
SELECT co.customer_id, ro.pickup_time, co.exclusions, co.extras, CASE
WHEN (exclusions IS NOT NULL AND exclusions NOT LIKE '%null%' AND exclusions > 0)  AND (extras IS NOT NULL AND extras NOT LIKE '%null%') AND (extras > 0) THEN 1
ELSE 0 END as both_
FROM customer_orders co
JOIN runner_orders ro
ON co.order_id = ro.order_id
HAVING ro.pickup_time NOT LIKE '%null%' AND both_ > 0;

#9 What was the total volume of pizzas ordered for each hour of the day?
SELECT a.order_time, a.days, a.hours, COUNT(a.pizza_id) as num_pizza FROM
(SELECT *, DAY(order_time) as days, HOUR(order_time) as hours FROM customer_orders) as a
GROUP BY a.days, a.hours;

#10 What was the volume of orders for each day of the week?
SELECT a.order_time, a.weeks, a.days, COUNT(a.pizza_id) as num_pizza FROM
(SELECT *, WEEK(order_time) as weeks, DAY(order_time) as days FROM customer_orders) as a
GROUP BY a.weeks, a.days