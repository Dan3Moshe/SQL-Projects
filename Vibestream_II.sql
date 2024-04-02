/*
Question #1: 
Vibestream is designed for users to share brief updates about how they are feeling, as such the platform enforces a character limit of 25. How many posts are exactly 25 characters long?


Expected column names: char_limit_posts
*/
SELECT COUNT(content) AS char_limit_posts
 FROM posts
 WHERE LENGTH(content)=25;




/*
Question #2:
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.


Find the difference in the number of posts these two users made on each day that at least one of them made a post. Return dates where the absolute value of the difference between posts made is greater than 2 (i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).
Expected column names: post_date


*/
WITH UserPosts AS (
        SELECT
            post_date,
            SUM(CASE WHEN user_id = 3 THEN 1 ELSE 0 END) AS James_posts,
            SUM(CASE WHEN user_id = 68 THEN 1 ELSE 0 END) AS Robert_posts
        FROM
            Posts
        WHERE
            user_id IN (3,68)
        GROUP BY
            post_date
)
SELECT
        post_date
FROM
        UserPosts
WHERE
        ABS(James_posts - Robert_posts) > 2;


/*
Question #3: 
Most users have relatively low engagement and few connections. User WilliamEagle6815, for example, has only 2 followers.
Network Analysts would say this user has two 1-step path relationships. Having 2 followers doesn’t mean WilliamEagle6815 is isolated, however. Through his followers, he is indirectly connected to the larger Vibestream network. 
Consider all users up to 3 steps away from this user:
* 1-step path (X → WilliamEagle6815)
* 2-step path (Y → X → WilliamEagle6815)
* 3-step path (Z → Y → X → WilliamEagle6815)
Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. Order by follower_id and return the top 10 records.


Expected column names: follower_id


*/
WITH RECURSIVE network AS (
        -- Base case: Users directly following WilliamEagle6815 (1-step path)
        SELECT
            follower_id,
            1 AS steps_away
        FROM
            follows
        WHERE
            followee_id=97
        
        UNION ALL
        
        -- Recursive case: Extend the path by one step
        SELECT
            f.follower_id,
            n.steps_away + 1 AS steps_away
        FROM
            follows f
        JOIN
            network n ON f.followee_id = n.follower_id
        WHERE
n.steps_away < 5-- Limiting to 4 steps away from WilliamEagle6815
)
-- Select all follower IDs within 4 steps of WilliamEagle6815
SELECT DISTINCT
        follower_id
FROM
        network
WHERE
        steps_away <= 4 AND NOT(follower_id=97) -- Excluding WilliamEagle6815
ORDER BY
        follower_id
  LIMIT 10;  


/*
Question #4: 
Return top posters for 2023-11-30 and 2023-12-01. A top poster is a user who has the most OR second most number of posts in a given day. Include the number of posts in the result and order the result by post_date and user_id.


Expected column names: post_date, user_id, posts


*/
WITH rankedposters AS (
        SELECT
            post_date,
            user_id,
            COUNT(*) AS num_posts,
            RANK() OVER (PARTITION BY post_date ORDER BY COUNT(*) DESC) AS poster_rank
        FROM
            Posts
        WHERE
            post_date IN ('2023-11-30', '2023-12-01')
        GROUP BY
            post_date,
            user_id
)
SELECT
        post_date,
        user_id,
        num_posts AS posts
FROM
        rankedposters
WHERE
        poster_rank <= 3 -- Selecting the top two posters
ORDER BY
        post_date,
        user_id;
