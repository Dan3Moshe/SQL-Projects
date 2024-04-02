/*
Question #1: 
Calculate the proportion of sessions abandoned in summer months 
(June, July, August) and compare it to the proportion of sessions abandoned 
in non-summer months. Round the output to 3 decimal places.


Expected column names: summer_abandon_rate, other_abandon_rate
*/


SELECT
  COUNT(DISTINCT(user_id)),
  CAST(SUM(CASE WHEN EXTRACT(MONTH FROM session_start) IN (6, 7, 8) AND (hotel_booked = FALSE AND flight_booked = FALSE)  THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN EXTRACT(MONTH FROM session_start) IN (6, 7, 8) THEN 1 ELSE 0 END) AS float) AS DECIMAL(4, 3)) AS summer_abandon_rate,
  CAST(SUM(CASE WHEN EXTRACT(MONTH FROM session_start) NOT IN (6, 7, 8) AND (hotel_booked = FALSE AND flight_booked = FALSE)  THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN EXTRACT(MONTH FROM session_start) NOT IN (6, 7, 8) THEN 1 ELSE 0 END) AS float) AS DECIMAL(4, 3)) AS other_abandon_rate
FROM sessions;




/*
Question #2: 
Bin customers according to their place in the session abandonment distribution as follows: 


1. number of abandonments greater than one standard deviation more than the mean. Call these customers “gt”.
2. number of abandonments fewer than one standard deviation less than the mean. Call these customers “lt”.
3. everyone else (the middle of the distribution). Call these customers “middle”.


calculate the number of customers in each group, the mean number of abandonments in each group, and the range of abandonments in each group.


Expected column names: distribution_loc, abandon_n, abandon_avg, abandon_range


*/


WITH abandonment_stats AS (
  SELECT
        user_id,
        SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE THEN 1 ELSE 0 END) AS abandonments,
        COUNT(user_id) AS total_sessions
  FROM sessions
  GROUP BY user_id
  HAVING SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE THEN 1 ELSE 0 END) != 0
  ORDER BY abandonments DESC
  )
 
SELECT
  CASE
        WHEN abandonments > (SELECT AVG(abandonments) FROM abandonment_stats)  + (SELECT STDDEV(abandonments) FROM abandonment_stats) THEN 'gt'
        WHEN abandonments < (SELECT AVG(abandonments) FROM abandonment_stats) - (SELECT STDDEV(abandonments) FROM abandonment_stats) THEN 'lt'
        ELSE 'middle'
  END AS distribution_loc,
  COUNT(user_id) AS abandon_n,
  AVG(abandonments) AS abandon_avg,
  MAX(abandonments) - MIN(abandonments) AS abandon_range
FROM abandonment_stats
GROUP BY distribution_loc;




/*
Question #3: 
Calculate the total number of abandoned sessions and the total number of sessions 
that resulted in a booking per day, but only for customers who reside in one of the 
top 5 cities (top 5 in terms of total number of users from city). 
Also calculate the ratio of booked to abandoned for each day. 
Return only the 5 most recent days in the dataset.


Expected column names: session_date, abandoned,booked, book_abandon_ratio


*/


WITH TopCities AS (
        SELECT home_city, COUNT(DISTINCT user_id) AS user_count
        FROM users
        GROUP BY home_city
        ORDER BY user_count DESC
        LIMIT 5
)
 
SELECT
        date(session_start) as session_date,
        SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE THEN 1 ELSE 0 END) AS abandoned,
        SUM(CASE WHEN hotel_booked = TRUE OR flight_booked = TRUE THEN 1 ELSE 0 END) AS booked,
        CASE
            WHEN SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE THEN 1 ELSE 0 END) > 0
            THEN CAST(SUM(CASE WHEN hotel_booked = TRUE OR flight_booked = TRUE THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE THEN 1 ELSE 0 END) AS float) AS DEC(4,3))
            ELSE 0
        END AS book_abandon_ratio
FROM sessions s
JOIN users u ON s.user_id = u.user_id
WHERE u.home_city IN (SELECT home_city FROM TopCities)
GROUP BY session_date
HAVING SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE THEN 1 ELSE 0 END)>0
ORDER BY session_date DESC
LIMIT 5;


/*
Question #4: 
Densely rank users from Saskatoon based on their ratio of successful bookings to abandoned bookings. 
then count how many users share each rank, with the most common ranks listed first.


note: if the ratio of bookings to abandons is null for a user, 
use the average bookings/abandons ratio of all Saskatoon users.


Expected column names: ba_rank, rank_count
*/


WITH saskatoonstats AS (
        SELECT
            s.user_id,
            CASE
            WHEN SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE AND cancellation=FALSE THEN 1 ELSE 0 END) > 0
            THEN CAST(SUM(CASE WHEN (hotel_booked = TRUE OR flight_booked = TRUE)AND cancellation=FALSE THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN hotel_booked = FALSE AND flight_booked = FALSE AND cancellation=FALSE THEN 1 ELSE 0 END) AS float) AS DEC(4,3))
            ELSE NULL END AS booking_abandon_ratio
        FROM sessions s
        JOIN users u ON s.user_id = u.user_id
        WHERE home_city = 'saskatoon'
        GROUP BY s.user_id
)
, finalresult AS (
        SELECT
            user_id,
            CASE
                WHEN booking_abandon_ratio = NULL THEN AVG(booking_abandon_ratio) OVER ()
                ELSE booking_abandon_ratio
            END AS adjusted_booking_abandon_ratio
        FROM saskatoonstats
)
 
SELECT
        DENSE_RANK() OVER (ORDER BY adjusted_booking_abandon_ratio DESC) AS ba_rank,
        COUNT(user_id) AS rank_count
FROM finalresult
GROUP BY adjusted_booking_abandon_ratio
ORDER BY rank_count DESC, ba_rank ;
