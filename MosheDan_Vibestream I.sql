/*
Question #1: 
Return the percentage of users who have posted more than 10 times 
rounded to 3 decimals.
Expected column names: more_than_10_posts
*/


-- q1 solution:


WITH question_one AS (
  SELECT
users.user_id AS userid,
COUNT(posts.post_id) AS posts_count
FROM users
LEFT JOIN posts
        ON users.user_id=posts.user_id


GROUP BY userid
)
SELECT 
  CAST(COUNT(CASE WHEN posts_count > 10 THEN 1 END)/CAST(COUNT(userid) AS float) AS DEC(4,3)) AS more_than_10_posts
  FROM question_one;




/*
Question #2: 
Recommend posts to user 888 by finding posts liked by users who have liked a post user 888 has also liked more than one time. 


The output should adhere to the following requirements: 


User 888 should not be recommend posts that they have already liked.
Of the posts that meet the criteria above, return only the three most popular posts (by number of likes). 
Return the post_ids in descending order.


Expected column names: post_id
*/


-- q2 solution:


WITH user888likes AS (
    SELECT post_id
    FROM likes
    WHERE user_id = 888
    GROUP BY post_id
    
)


-- Find users who have liked the same posts as user 888
, userswithsimilarlikes AS (
    SELECT user_id
    FROM likes
    WHERE post_id IN (SELECT post_id FROM user888likes)
    GROUP BY user_id
    Having COUNT(*)>1
)


-- Find posts liked by users with similar likes, excluding posts liked by user 888
, recommendedposts AS (
    SELECT post_id, COUNT(user_id) AS like_count
    FROM likes
    WHERE user_id IN (SELECT user_id FROM userswithsimilarlikes) AND post_id NOT IN (SELECT post_id FROM User888Likes)
    GROUP BY post_id
)


-- Rank the recommended posts by the number of likes
, rankedposts AS (
    SELECT post_id, like_count,
           RANK() OVER (ORDER BY like_count DESC) AS rnk
    FROM recommendedposts
)


-- Select the top 3 recommended posts
SELECT post_id
FROM rankedposts
ORDER BY like_count DESC
LIMIT 3;
/*
Question #3: 
Vibestream wants to track engagement at the user level. When a user makes their first post, the team wants to begin tracking the cumulative sum of posts over time for the user.


Return a table showing the date and the total number of posts user 888 has made to date. The time series should begin at the date of 888’s first post and end at the last available date in the posts table.


Expected column names: post_date, posts_made
*/


-- q3 solution:


-- Generate a series of dates from the first post date to the last available date in the posts table
WITH dateseries AS (
    SELECT generate_series(
        ( SELECT MIN(post_date)
           FROM posts
           WHERE user_id = 888)::timestamp,
        (SELECT MAX(post_date)
         FROM posts )::timestamp,
        interval '1 day'
    )::date AS post_date
)


-- Count the cumulative sum of posts made by user 888 for each date
, cumulativeposts AS (
    SELECT
        ds.post_date,
        COUNT(p.post_id) OVER (ORDER BY ds.post_date) AS posts_made
    FROM dateseries ds
    LEFT JOIN posts p 
  ON ds.post_date = p.post_date AND p.user_id = 888
)


-- Select the date and the total number of posts made by user 888 to date
SELECT post_date, posts_made
FROM cumulativeposts;


/*
Question #4: 
The Vibestream feed algorithm updates with user preferences every day. Every update is independent of the previous update. Sometimes the update fails because Vibestreams systems are unreliable. 


Write a query to return the update state for each continuous interval of days in the period from 2023-01-01 to 2023-12-30.


the algo_update is 'failed' if tasks in a date interval failed and 'succeeded' if tasks in a date interval succeeded. every interval has a  start_dateand an end_date.


Return the result in ascending order by start_date.


Expected column names: algo_update, start_date, end_date
*/


-- q4 solution:


WITH alldates AS (
    SELECT fail_date AS update_date, 'failed' AS algo_update
    FROM algo_update_failure
    WHERE fail_date BETWEEN '2023-01-01' AND '2023-12-30'
    UNION
    SELECT success_date AS update_date, 'succeeded' AS algo_update
    FROM algo_update_success
    WHERE success_date BETWEEN '2023-01-01' AND '2023-12-30'
)


SELECT 
    algo_update,
    MIN(update_date) AS start_date,
    MAX(update_date) AS end_date
FROM (
    SELECT 
        update_date,
        algo_update,
        ROW_NUMBER() OVER (ORDER BY update_date) -
        ROW_NUMBER() OVER (PARTITION BY algo_update ORDER BY update_date) AS grp
    FROM alldates
) AS grouped
GROUP BY grp, algo_update
ORDER BY start_date;