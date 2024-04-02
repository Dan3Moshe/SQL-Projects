/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the total value of parts installed by the installer.


Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.


Expected column names: name, bonus
*/


-- q1 solution:


SELECT 
    i.name,
    ROUND(SUM(p.price * o.quantity) * 0.1) AS bonus
FROM 
    installers i
JOIN 
    installs ins ON i.installer_id = ins.installer_id
JOIN 
    orders o ON ins.order_id = o.order_id
JOIN 
    parts p ON o.part_id = p.part_id
GROUP BY 
    i.name
ORDER BY 
    bonus ASC;


/*
Question #2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” where installers face off to see who can change a part the fastest in a tournament style contest.


Derby points are awarded as follows:


- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).


We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by `installer_id` in increasing order.


Expected column names: `installer_id`, `name`, `num_points`


*/


-- q2 solution:


with installer1_outcomes as 
(
select
    installer_one_id as installer_id,
    case when installer_one_time < installer_two_time then 3
    when installer_one_time = installer_two_time then 1
    else 0 end as points
    from install_derby
),
installer2_outcomes as
(
select
    installer_two_id as installer_id,
    case when installer_two_time < installer_one_time then 3
    when installer_one_time = installer_two_time then 1
    else 0 end as points
    from install_derby

),
combo as 
(
select
    *
from
    installer1_outcomes
union all
select
    *
from
    installer2_outcomes
)
select
    i.installer_id,
    i.name,
    coalesce(sum(c.points),0) as num_points
from 
    installers i
left join
    combo c
on
    i.installer_id = c.installer_id
group by
    i.installer_id,
    i.name
order by
    num_points desc,
    installer_id;




/*
Question #3:


Write a query to find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, you should find the install with the smallest `derby_id`.


Return the result table ordered by `installer_id` in ascending order.


Expected column names: `derby_id`, `installer_id`, `install_time`
*/


-- q3 solution:


SELECT 
    sub.derby_id,
    sub.installer_id,
    sub.install_time
FROM (
    SELECT 
        id.derby_id,
        id.installer_id,
        id.install_time,
        ROW_NUMBER() OVER (PARTITION BY id.installer_id ORDER BY id.install_time, id.derby_id) AS row_num
    FROM (
        SELECT 
            installer_one_id AS installer_id,
            derby_id,
            installer_one_time AS install_time
        FROM 
            install_derby
        UNION ALL
        SELECT 
            installer_two_id AS installer_id,
            derby_id,
            installer_two_time AS install_time
        FROM 
            install_derby
    ) AS id
) AS sub
WHERE 
    sub.row_num = 1
ORDER BY 
    sub.installer_id ASC;




/*
Question #4: 
Write a solution to calculate the total parts spending by customers paying for installs on each Friday of every week in November 2023. 
If there are no purchases on the Friday of a particular week, the parts total should be set to `0`.


Return the result table ordered by week of month in ascending order.


Expected column names: `november_fridays`, `parts_total`
*/


-- q4 solution:


WITH november_fridays AS (
    SELECT generate_series::date AS november_fridays
    FROM generate_series('2023-11-01'::date, '2023-11-30'::date, '1 day'::interval) generate_series
    WHERE EXTRACT('dow' FROM generate_series) = 5
)
SELECT 
    nf.november_fridays,
    COALESCE(SUM(p.price * o.quantity), 0) AS parts_total
FROM 
    november_fridays nf
LEFT JOIN 
    installs i ON  i.install_date::date = nf.november_fridays
LEFT JOIN 
    orders o ON i.order_id = o.order_id
LEFT JOIN 
    parts p ON o.part_id = p.part_id
GROUP BY 
    nf.november_fridays
ORDER BY 
    nf.november_fridays;