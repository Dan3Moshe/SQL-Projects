/*
Question #1:


Write a query to find the customer(s) with the most orders. 
Return only the preferred name.


Expected column names: preferred_name
*/


-- q1 solution:


WITH cte AS
(SELECT customer_id,
           RANK() OVER (ORDER BY COUNT(order_id) DESC) AS RANK
FROM orders
GROUP BY customer_id)
SELECT preferred_name
FROM customers
GROUP BY customer_id
HAVING customer_id=(SELECT customer_id FROM cte WHERE RANK=1);




/*
Question #2: 
RevRoll does not install every part that is purchased. 
Some customers prefer to install parts themselves. 
This is a valuable line of business 
RevRoll wants to encourage by finding valuable self-install customers and sending them offers.


Return the customer_id and preferred name of customers 
who have made at least $2000 of purchases in parts that RevRoll did not install. 


Expected column names: customer_id, preferred_name


*/


-- q2 solution:


SELECT c.customer_id,
           c.preferred_name
FROM customers c
JOIN orders o ON o.customer_id=c.customer_id
JOIN parts p ON o.part_id=p.part_id
LEFT JOIN installs i ON o.order_id = i.order_id
WHERE i.order_id IS NULL -- Excludes orders that are part of any installs
GROUP BY c.customer_id, c.preferred_name
HAVING SUM(p.price*o.quantity)>=2000
ORDER BY c.customer_id;


/*
Question #3: 
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil 
but did not buy an Air Filter since we want to recommend these customers buy an Air Filter.
Return the result table ordered by `customer_id`.


Expected column names: customer_id, preferred_name


*/


-- q3 solution:


SELECT c.customer_id,
           c.preferred_name
FROM customers c
JOIN orders o ON o.customer_id=c.customer_id
JOIN parts p ON o.part_id=p.part_id
GROUP BY c.customer_id, c.preferred_name
HAVING SUM(CASE WHEN p.name = 'Oil Filter' THEN 1 ELSE 0 END) > 0
            AND SUM(CASE WHEN p.name = 'Engine Oil' THEN 1 ELSE 0 END) > 0
            AND SUM(CASE WHEN p.name = 'Air Filter' THEN 1 ELSE 0 END) = 0
Order BY c.customer_id;




/*
Question #4: 


Write a solution to calculate the cumulative part summary for every part that 
the RevRoll team has installed.


The cumulative part summary for an part can be calculated as follows:


- For each month that the part was installed, 
sum up the price*quantity in **that month** and the **previous two months**. 
This is the **3-month sum** for that month. 
If a part was not installed in previous months, 
the effective price*quantity for those months is 0.
- Do **not** include the 3-month sum for the **most recent month** that the part was installed.
- Do **not** include the 3-month sum for any month the part was not installed.


Return the result table ordered by `part_id` in ascending order. In case of a tie, order it by `month` in descending order. Limit the output to the first 10 rows.


Expected column names: part_id, month, part_summary
*/


-- q4 solution:


 
WITH cte AS (
        SELECT
            p.part_id AS part_id,
            EXTRACT(MONTH FROM i.install_date) AS month,
            SUM(p.price * o.quantity) AS part_summary
        FROM
            parts p
            JOIN orders o ON p.part_id = o.part_id
            JOIN installs i ON i.order_id = o.order_id
        GROUP BY
            p.part_id, EXTRACT(MONTH FROM i.install_date)
),
-- Filling in missing months where there weren’t any installs
all_months AS (
        SELECT
            part_id,
            GENERATE_SERIES(1,12) AS month  
        FROM
            parts
        UNION
        SELECT
            part_id,
            month
        FROM
            cte
),
results AS(
SELECT
        all_months.part_id AS part_id,
        all_months.month AS month,
        COALESCE(SUM(part_summary) OVER (PARTITION BY all_months.part_id ORDER BY all_months.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS part_summary --Summing up 3 consecutive months 
FROM
        all_months
LEFT JOIN
        cte ON all_months.part_id = cte.part_id AND all_months.month = cte.month
WHERE
        all_months.month != (SELECT MAX(month) FROM cte) -- Excluding most recent month
ORDER BY
        all_months.part_id ASC, all_months.month DESC)
SELECT r.part_id,
           r.month,
           r.part_summary
FROM results r
JOIN cte c ON r.part_id=c.part_id AND c.month=r.month -- Only displaying months where install happened on
LIMIT 10;