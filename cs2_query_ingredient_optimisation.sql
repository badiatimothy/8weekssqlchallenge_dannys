USE pizza_runner;

#1 What are the standard ingredients for each pizza?
SELECT * FROM pizza_recipes;

#2 What was the most commonly added extra?
WITH c as (WITH b as (WITH a as
(SELECT * FROM customer_orders
WHERE extras NOT LIKE '%null%' AND extras > 0)
SELECT *, SUBSTRING(extras, 1, 1) as ex1, SUBSTRING(extras, 4, 4) as ex2 FROM a)
SELECT ex1 FROM b
UNION ALL(SELECT ex2 FROM b WHERE ex2 > 0))
SELECT ex1 as extra, pt.topping_name, COUNT(ex1) as num FROM c JOIN pizza_toppings pt ON c.ex1 = pt.topping_id
GROUP BY extra ORDER BY num DESC;

#3 What was the most common exclusion?
WITH b as (WITH a as(
(SELECT SUBSTRING(exclusions, 1, 1) as exc1, SUBSTRING(exclusions, 4, 4) as exc2 FROM customer_orders
WHERE exclusions > 0))
SELECT a.exc1 FROM a
UNION ALL
(SELECT a.exc2 FROM a WHERE exc2 > 0))
SELECT exc1 as exclusions, pt.topping_name, COUNT(exc1) as num_exc FROM b JOIN pizza_toppings pt ON b.exc1 = pt.topping_id
GROUP BY exc1 ORDER BY num_exc DESC;

