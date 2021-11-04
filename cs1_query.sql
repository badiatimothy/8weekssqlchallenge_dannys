use dannys_diner;

#1 What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, COUNT(s.product_id) as items, SUM(m.price) as total_amount FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

#2 How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) as days 
FROM sales
GROUP BY customer_id;

#3 What was the first item from the menu purchased by each customer?
SELECT a.customer_id, a.order_date, a.product_name FROM 
(SELECT s.customer_id, s.order_date, m.product_name, 
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) as row_nums FROM sales s
JOIN menu m ON m.product_id = s.product_id) as a
WHERE row_nums = 1;

#4 What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT s.product_id, m.product_name, COUNT(s.product_id) as num_product FROM sales s JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.product_id
ORDER BY num_product DESC
LIMIT 1;

#5 Which item was the most popular for each customer?
SELECT b.* FROM
(SELECT a.*, ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.num_product DESC) as row_nums FROM
(SELECT s.customer_id, s.product_id, m.product_name, COUNT(s.product_id) as num_product FROM sales s JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id, s.product_id) as a) as b
WHERE row_nums = 1;

#6 Which item was purchased first by the customer after they became a member?
SELECT b.product_name, b.customer_id, b.order_date FROM
(SELECT a.product_name, a.customer_id, a.order_date,
ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.order_date ASC) as row_nums FROM
(SELECT m.product_id, m.product_name, s.customer_id, s.order_date, ms.join_date,
CASE WHEN s.order_date >= ms.join_date THEN 1 ELSE 0 END as yn
 FROM 
menu m JOIN sales s ON m.product_id = s.product_id
JOIN members ms ON s.customer_id = ms.customer_id
HAVING yn = 1) as a) as b
WHERE b.row_nums = 1 ;

#7 Which item was purchased just before the customer became a member?
SELECT b.product_name, b.customer_id, b.order_date FROM (
SELECT a.product_name, a.customer_id, a.order_date,
ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.order_date DESC) as row_nums FROM
(SELECT m.product_id, m.product_name, s.customer_id, s.order_date, ms.join_date,
CASE WHEN s.order_date >= ms.join_date THEN 1 ELSE 0 END as yn
 FROM 
menu m JOIN sales s ON m.product_id = s.product_id
JOIN members ms ON s.customer_id = ms.customer_id
HAVING yn = 0) as a) as b
WHERE b.row_nums = 1;

#8 What is the total items and amount spent for each member before they became a member?
SELECT a.customer_id, COUNT(a.product_name) as total_item, SUM(a.price) as total_spent FROM
(SELECT m.product_id, m.price, m.product_name, s.customer_id, s.order_date, ms.join_date,
CASE WHEN s.order_date >= ms.join_date THEN 1 ELSE 0 END as yn
 FROM 
menu m JOIN sales s ON m.product_id = s.product_id
JOIN members ms ON s.customer_id = ms.customer_id
HAVING yn = 0) as a
GROUP BY a.customer_id;

#9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with a as
(SELECT s.customer_id, m.product_id, m.product_name, m.price,
CASE WHEN m.product_name = 'sushi' THEN m.price*10*2
ELSE m.price*10 END as points
FROM menu m JOIN sales s ON m.product_id = s.product_id)
SELECT a.customer_id, SUM(a.points) as tot_points FROM a
GROUP BY a.customer_id;

#10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM(IF( s.order_date >= ms.join_date AND s.order_date <= date_add(ms.join_date,INTERVAL 7 DAY), m.price*20, m.price*10)) as new_points 
FROM menu m JOIN sales s ON m.product_id = s.product_id
JOIN members ms ON ms.customer_id = s.customer_id
WHERE order_date <= '2021-01-31'
GROUP BY customer_id;

#BONUS
#Recreate the following table output using the available data
SELECT s.customer_id, s.order_date, m.product_name, m.price, CASE
WHEN s.order_date >= ms.join_date THEN 'Y' ELSE 'N' END as member
FROM menu m JOIN sales s ON m.product_id = s.product_id
JOIN members ms ON s.customer_id = ms.customer_id
ORDER BY s.customer_id, s.order_date;

#Danny also requires further information about the ranking of customer products, 
#but he purposely does not need the ranking for non-member purchases so he expects 
#null ranking values for the records when customers are not yet part of the loyalty program.

SELECT a.*, CASE WHEN a.member = 'N' THEN 'null'
ELSE RANK() OVER(PARTITION BY a.customer_id, a.member ORDER BY a.order_date ASC)  
END  as ranking
FROM 
(SELECT s.customer_id, s.order_date, m.product_name, m.price, CASE
WHEN s.order_date >= ms.join_date THEN 'Y' ELSE 'N' END as member
FROM menu m JOIN sales s ON m.product_id = s.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
ORDER BY s.customer_id, s.order_date) as a;
