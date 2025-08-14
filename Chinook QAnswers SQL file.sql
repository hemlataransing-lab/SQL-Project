-- Objective Questions and answers-----------------------------------------------------------------------
use chinook;
select * from track;

SELECT track_id, COUNT(*)
FROM track
GROUP BY track_id
HAVING COUNT(*) > 1;

-- Answer to Q1 - Does any table have missing values ? If yes, how would you handle it?
SELECT 'artist' AS table_name, COUNT(*) AS null_count
FROM artist
WHERE name IS NULL
UNION ALL
SELECT 'customer', COUNT(*) FROM customer WHERE company IS NULL OR address IS NULL OR city IS NULL OR state IS NULL OR postal_code IS NULL OR phone IS NULL OR fax IS NULL OR support_rep_id IS NULL
UNION ALL
SELECT 'employee', COUNT(*) FROM employee WHERE reports_to IS NULL OR title IS NULL OR birthdate IS NULL OR hire_date IS NULL OR phone IS NULL OR fax IS NULL OR email IS NULL
UNION ALL
SELECT 'genre', COUNT(*) FROM genre WHERE name IS NULL
UNION ALL
SELECT 'invoice', COUNT(*) FROM invoice WHERE billing_address IS NULL OR billing_city IS NULL OR billing_state IS NULL OR billing_postal_code IS NULL
UNION ALL
SELECT 'media_type', COUNT(*) FROM media_type WHERE name IS NULL
UNION ALL
SELECT 'playlist', COUNT(*) FROM playlist WHERE name IS NULL
UNION ALL
SELECT 'track', COUNT(*) FROM track WHERE album_id IS NULL OR genre_id IS NULL OR composer IS NULL OR bytes IS NULL;

-- Ans to Q1 How will you handle null values?
    
    SELECT
    first_name,
    last_name,
    COALESCE(company, 'NA') AS company,
    COALESCE(address, 'NA') AS address,
    COALESCE(city, 'NA') AS city,
    COALESCE(state, 'NA') AS state,
    COALESCE(country, 'NA') AS country,
    COALESCE(postal_code, 'NA') AS postal_code,
    COALESCE(phone, 'NA') AS phone,
    COALESCE(fax, 'NA') AS fax,
    COALESCE(support_rep_id, 'NA') AS support_rep_id
FROM customer;

SELECT
    employee_id,
    COALESCE(last_name, 'NA') AS last_name,
    COALESCE(first_name, 'NA') AS first_name,
    COALESCE(title, 'NA') AS title,
    COALESCE(CAST(reports_to AS CHAR), 'NA') AS reports_to,
    COALESCE(CAST(birthdate AS CHAR), 'NA') AS birthdate,
    COALESCE(CAST(hire_date AS CHAR), 'NA') AS hire_date,
    COALESCE(address, 'NA') AS address,
    COALESCE(city, 'NA') AS city,
    COALESCE(state, 'NA') AS state,
    COALESCE(country, 'NA') AS country,
    COALESCE(postal_code, 'NA') AS postal_code,
    COALESCE(phone, 'NA') AS phone,
    COALESCE(fax, 'NA') AS fax,
    COALESCE(email, 'NA') AS email
FROM employee;

SELECT
    track_id,
    name,
    COALESCE(CAST(album_id AS CHAR), 'NA') AS album_id,
    COALESCE(CAST(genre_id AS CHAR), 'NA') AS genre_id,
    COALESCE(composer, 'NA') AS composer,
    milliseconds,
    COALESCE(CAST(bytes AS CHAR), 'NA') AS bytes,
    unit_price
FROM track;


-- Ans to Q2 - Find the top-selling tracks and top artist in the USA and identify their most famous genres

WITH usa_sales AS (
    SELECT 
        il.track_id,
        il.unit_price * il.quantity AS revenue,
        i.billing_country
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    WHERE i.billing_country = 'USA'
),
track_artist_genre AS (
    SELECT 
        t.track_id,
        t.name AS track_name,
        ar.artist_id,
        ar.name AS artist_name,
        g.genre_id,
        g.name AS genre_name
    FROM track t
    JOIN album al ON t.album_id = al.album_id
    JOIN artist ar ON al.artist_id = ar.artist_id
    LEFT JOIN genre g ON t.genre_id = g.genre_id
),
artist_sales AS (
    SELECT 
        tag.artist_id,
        tag.artist_name,
        SUM(us.revenue) AS total_artist_sales
    FROM usa_sales us
    JOIN track_artist_genre tag ON us.track_id = tag.track_id
    GROUP BY tag.artist_id, tag.artist_name
),
top_artist AS (
    SELECT artist_id, artist_name
    FROM artist_sales
    ORDER BY total_artist_sales DESC
    LIMIT 1
),
top_artist_tracks AS (
    SELECT 
        tag.track_name,
        tag.genre_name,
        SUM(us.revenue) AS track_revenue
    FROM usa_sales us
    JOIN track_artist_genre tag ON us.track_id = tag.track_id
    JOIN top_artist ta ON tag.artist_id = ta.artist_id
    GROUP BY tag.track_name, tag.genre_name
),
top_genre AS (
    SELECT 
        genre_name,
        COUNT(*) AS track_count
    FROM top_artist_tracks
    GROUP BY genre_name
    ORDER BY track_count DESC
    LIMIT 1
)

SELECT 
    ta.artist_name AS top_artist_in_usa,
    tg.genre_name AS most_popular_genre,
    tt.track_name AS top_track,
    tt.track_revenue
FROM top_artist ta
JOIN top_genre tg ON 1=1
JOIN top_artist_tracks tt ON 1=1
ORDER BY tt.track_revenue DESC
LIMIT 10;

-- Ans to Q3 What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
select country,coalesce(state,'NA') as state,city,count(customer_id) as total_customer from customer
group by country,state,city
order by country,state,city;

-- Ans to Q4 Calculate the total revenue and number of invoices for each country, state, and city.
SELECT
    i.billing_country AS country,
    i.billing_state AS state,
    i.billing_city AS city,
    COUNT(DISTINCT i.invoice_id) AS invoice_count,
    SUM(il.unit_price * il.quantity) AS total_revenue
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY i.billing_country, i.billing_state, i.billing_city
ORDER BY total_revenue DESC;

-- Ans to Q5 Find the top 5 customers by total revenue in each country
WITH customer_revenue AS (
    SELECT
        c.country,
        c.customer_id,
        concat(c.first_name," ",c.last_name) AS customer_name,
        SUM(il.unit_price * il.quantity) AS total_revenue
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.country, c.customer_id,customer_name
),
ranked_customers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM customer_revenue
)
SELECT *
FROM ranked_customers
WHERE revenue_rank <= 5
ORDER BY country, revenue_rank;

-- Ans to Q6 Identify the top-selling track for each customer
WITH customer_track_sales AS (
    SELECT
        c.customer_id,
        concat(c.first_name," ",c.last_name) AS customer_name,
        t.track_id,
        t.name AS track_name,
        SUM(il.quantity) AS total_quantity
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    GROUP BY c.customer_id, c.first_name, c.last_name, t.track_id, t.name
),
ranked_tracks AS (
    SELECT *,
           RANK() OVER (ORDER BY total_quantity DESC) AS track_rank
    FROM customer_track_sales
)
SELECT *
FROM ranked_tracks
WHERE track_rank = 1
ORDER BY customer_id;

-- Ans to Q7 Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?
-- Type1.Frequency of purchase
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    COUNT(i.invoice_id) AS total_purchases
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY total_purchases DESC;

-- Type2. Average order value
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    COUNT(i.invoice_id) AS total_orders,
    ROUND(SUM(i.total)/COUNT(i.invoice_id), 2) AS avg_order_value,
    SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY avg_order_value DESC;

-- Type3. Tracking customer preferences
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    g.name AS genre_name,
    COUNT(*) AS total_tracks
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id, genre_name
ORDER BY c.customer_id, total_tracks DESC;
-- Objective Questions and Answers--
-- Ans to Q8 what is the customer churn rate?
SELECT 
    ROUND(100.0 * 
        SUM(CASE WHEN last_purchase < '2020-12-30' OR last_purchase IS NULL THEN 1 ELSE 0 END) 
        / COUNT(*), 2
    ) AS churn_rate_percentage
FROM (
    SELECT c.customer_id, MAX(i.invoice_date) AS last_purchase
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
) AS customer_last_purchase;

-- Ans to Q8 What is the customer churn rate?
SELECT ROUND(100.0 * SUM(CASE WHEN last_purchase < '2020-12-30' OR last_purchase IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2 ) AS churn_rate_percentage FROM 
( SELECT c.customer_id, MAX(i.invoice_date) AS last_purchase FROM customer c LEFT JOIN invoice i ON c.customer_id = i.customer_id GROUP BY c.customer_id ) AS customer_last_purchase; 

-- Ans to Q9. Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists. 
WITH SalesGenreRankUSA AS (
	SELECT
		g.name AS genre, ar.name AS artist, SUM(i.total) AS genre_sales,
        DENSE_RANK() OVER( PARTITION BY g.name ORDER BY SUM(i.total) DESC) AS genre_rank	
	FROM genre g
    LEFT JOIN track t ON g.genre_id = t.genre_id
    LEFT JOIN invoice_line il ON t.track_id = il.track_id
    LEFT JOIN invoice i ON il.invoice_id = i.invoice_id
    LEFT JOIN album a ON t.album_id = a.album_id
    LEFT JOIN artist ar ON a.artist_id = ar.artist_id
    WHERE i.billing_country = 'USA'
    GROUP BY 1,2
),

TotalSalesUSA AS (
	SELECT 
		SUM(i.total) AS total_sales
	FROM invoice_line il 
    LEFT JOIN invoice i ON il.invoice_id = i.invoice_id
    WHERE i.billing_country = 'USA'
)

SELECT s.genre,s.artist,s.genre_sales,t.total_sales, ROUND((s.genre_sales / t.total_sales)* 100,2) AS percent_sales
FROM SalesGenreRankUSA s JOIN TotalSalesUSA t
ORDER BY s.genre_sales DESC, s.genre ASC;

-- Ans to Q10 Find customers who have purchased tracks from at least 3 different genres
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    COUNT(DISTINCT g.genre_id) AS genre_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT g.genre_id) >= 3
ORDER BY genre_count DESC;

-- Ans to Q11 Rank genres based on their sales performance in the USA
SELECT 
    g.name AS genre,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS total_sales,
    RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS genre_rank
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.genre_id, g.name
ORDER BY genre_rank;

-- Ans to Q12 Identify customers who have not made a purchase in the last 3 months.
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    MAX(i.invoice_date) AS last_purchase_date
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
HAVING last_purchase_date IS NULL 
    OR last_purchas
    
    
-- Subjective Questions And answers----------------------------------------------------------
-- Ans to Q1 Recommend the three albums from the new record label
Select 
g.name as genre_name,
al.title as album_title,
sum(il.quantity*tr.unit_price) as total_sales,
dense_rank() over(order by sum(il.quantity*tr.unit_price)) as sales_rank
from track tr
join album al on tr.album_id=al.album_id
join invoice_line il on tr.track_id=il.track_id
join invoice inv on il.invoice_id=inv.invoice_id
join genre g on tr.genre_id=g.genre_id
where inv.billing_country='USA'
group by genre_name,album_title
order by sales_rank
limit 3;

-- Ans to Q2 Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
 SELECT 
    c.country,
    g.name AS genre_name,
    SUM(il.unit_price * il.quantity) AS total_sales
FROM 
    invoice i
JOIN 
    customer c ON i.customer_id = c.customer_id
JOIN 
    invoice_line il ON i.invoice_id = il.invoice_id
JOIN 
    track t ON il.track_id = t.track_id
JOIN 
    genre g ON t.genre_id = g.genre_id
WHERE 
    c.country <> 'USA'
GROUP BY 
    c.country, g.name
ORDER BY 
    c.country,
    total_sales DESC;
    
    
    WITH GenreSales AS (
    SELECT 
        c.country,
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM 
        invoice i
    JOIN 
        customer c ON i.customer_id = c.customer_id
    JOIN 
        invoice_line il ON i.invoice_id = il.invoice_id
    JOIN 
        track t ON il.track_id = t.track_id
    JOIN 
        genre g ON t.genre_id = g.genre_id
    WHERE 
        c.country <> 'USA'
    GROUP BY 
        c.country, g.name
),
RankedGenres AS (
    SELECT *,
           RANK() OVER (PARTITION BY country ORDER BY total_sales DESC) AS genre_rank
    FROM GenreSales
)
SELECT 
    country,
    genre_name,
    total_sales,
    genre_rank
FROM 
    RankedGenres
WHERE 
    genre_rank <= 3
ORDER BY 
    country asc, genre_rank asc,total_sales desc;
    
-- Ans to Q3 Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers?
SET @max_invoice_date = (SELECT MAX(invoice_date) FROM invoice);

--  Classify customers based on their first purchase date
SELECT 
    customer_id,
    MIN(invoice_date) AS first_purchase_date,MAX(invoice_date) as latest_purcahsedate,
    CASE 
        WHEN MIN(invoice_date) >= DATE_SUB(@max_invoice_date, INTERVAL 36 MONTH)
        THEN 'New'
        ELSE 'Long-term'
    END AS customer_type
FROM invoice
GROUP BY customer_id;

SET @max_invoice_date = (SELECT MAX(invoice_date) FROM invoice);

-- final aggregation
SELECT 
    customer_type,
    ROUND(AVG(purchase_frequency), 2) AS avg_frequency,
    ROUND(AVG(avg_basket_size), 2) AS avg_basket_size,
    ROUND(AVG(avg_spending), 2) AS avg_invoice_spending
FROM (
    SELECT 
        c.customer_id,
        CASE 
            WHEN MIN(i.invoice_date) >= DATE_SUB(@max_invoice_date, INTERVAL 36 MONTH)
                THEN 'New'
            ELSE 'Long-term'
        END AS customer_type,
        COUNT(DISTINCT i.invoice_id) AS purchase_frequency,
        SUM(il.quantity) / COUNT(DISTINCT i.invoice_id) AS avg_basket_size,
        AVG(i.total) AS avg_spending
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id
) AS customer_stats
GROUP BY customer_type;

-- Ans to Q4 Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers
-- Genre combinations purchased by the same customer
SELECT 
    g1.name AS genre_1,
    g2.name AS genre_2,
    COUNT(DISTINCT i.customer_id) AS customer_count
FROM invoice i
JOIN invoice_line il1 ON i.invoice_id = il1.invoice_id
JOIN track t1 ON il1.track_id = t1.track_id
JOIN genre g1 ON t1.genre_id = g1.genre_id

JOIN invoice_line il2 ON i.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN genre g2 ON t2.genre_id = g2.genre_id

WHERE g1.genre_id < g2.genre_id  -- avoid duplicates like (Rock, Rock)
GROUP BY g1.name, g2.name
ORDER BY customer_count DESC
LIMIT 20;

-- Artist combinations purchased by the same customer
SELECT 
    a1.name AS artist_1,
    a2.name AS artist_2,
    COUNT(DISTINCT i.customer_id) AS customer_count
FROM invoice i
JOIN invoice_line il1 ON i.invoice_id = il1.invoice_id
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN artist a1 ON al1.artist_id = a1.artist_id

JOIN invoice_line il2 ON i.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
JOIN artist a2 ON al2.artist_id = a2.artist_id

WHERE a1.artist_id < a2.artist_id
GROUP BY a1.name, a2.name
ORDER BY customer_count DESC
LIMIT 20;

-- Album combinations purchased by the same customer
SELECT 
    al1.title AS album_1,
    al2.title AS album_2,
    COUNT(DISTINCT i.customer_id) AS customer_count
FROM invoice i
JOIN invoice_line il1 ON i.invoice_id = il1.invoice_id
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id

JOIN invoice_line il2 ON i.invoice_id = il2.invoice_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id

WHERE al1.album_id < al2.album_id
GROUP BY al1.title, al2.title
ORDER BY customer_count DESC
LIMIT 20;

-- Ans to Q5 Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations?
-- Purchase Behaviour Analysis--
SELECT 
    c.country,
    COUNT(DISTINCT i.invoice_id) / COUNT(DISTINCT c.customer_id) AS avg_purchases,
    SUM(il.quantity) / COUNT(DISTINCT i.invoice_id) AS avg_basket_size,
    AVG(i.total) AS avg_invoice_amount
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.country
ORDER BY avg_purchases DESC;

-- Regional Churn rate --
--  Get each customer's last purchase date
WITH CustomerLastPurchase AS (
    SELECT 
        c.customer_id,
        c.country,
        MAX(i.invoice_date) AS last_purchase
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country
)
-- Aggregate churn stats per country
SELECT 
    country,
    COUNT(*) AS total_customers,
    SUM(CASE 
        WHEN last_purchase < DATE_SUB(@max_invoice_date, INTERVAL 6 MONTH) 
        THEN 1 ELSE 0 
    END) AS churned_customers,
    ROUND(SUM(CASE 
        WHEN last_purchase < DATE_SUB(@max_invoice_date, INTERVAL 6 MONTH) 
        THEN 1 ELSE 0 
    END) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM CustomerLastPurchase
GROUP BY country
ORDER BY churn_rate_percent DESC;

-- Ans to Q6 Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are more likely to churn or pose a higher risk of reduced spending? 
SET @max_invoice_date = (SELECT MAX(invoice_date) FROM invoice);

-- Step 2: Create base stats per customer
WITH CustomerStats AS (
    SELECT 
        c.customer_id,
        c.country,
        c.city,
        MAX(i.invoice_date) AS last_purchase,
        COUNT(DISTINCT i.invoice_id) AS total_invoices,
        AVG(i.total) AS avg_spending,
        SUM(i.total) AS lifetime_spending
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country, c.city
)

-- Step 3: Apply risk flags
SELECT 
    customer_id,
    country,
    city,
    total_invoices,
    ROUND(avg_spending, 2) AS avg_invoice_spending,
    ROUND(lifetime_spending, 2) AS total_spent,
    CASE 
        WHEN last_purchase < DATE_SUB(@max_invoice_date, INTERVAL 6 MONTH) THEN 'High Risk (Churn)'
        WHEN avg_spending < 5 THEN 'Medium Risk (Low Spend)'
        ELSE 'Low Risk (Active)'
    END AS risk_level
FROM CustomerStats
ORDER BY risk_level, country, customer_id;

-- Ans to Q7 -Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer segments?
-- Set max invoice date
SET @max_invoice_date = (SELECT MAX(invoice_date) FROM invoice);

-- CLTV metrics per customer
SELECT 
    c.customer_id,
    c.country,
    MIN(i.invoice_date) AS first_purchase,
    MAX(i.invoice_date) AS last_purchase,
    DATEDIFF(@max_invoice_date, MIN(i.invoice_date)) / 30 AS tenure_months,
    COUNT(DISTINCT i.invoice_id) AS total_orders,
    ROUND(SUM(i.total) / COUNT(DISTINCT i.invoice_id), 2) AS avg_order_value,
    ROUND(SUM(i.total), 2) AS lifetime_spend,
    ROUND((SUM(i.total) / COUNT(DISTINCT i.invoice_id)) * (COUNT(DISTINCT i.invoice_id) / (DATEDIFF(@max_invoice_date, MIN(i.invoice_date)) / 30)), 2) AS predicted_cltv
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.country;

-- Analyse Churned customers= No purchase in last 6 months 
SELECT 
    c.customer_id,
    c.country,
    COUNT(DISTINCT i.invoice_id) AS total_orders,
    ROUND(SUM(i.total), 2) AS total_spent,
    MAX(i.invoice_date) AS last_purchase_date
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.country
HAVING last_purchase_date < DATE_SUB(@max_invoice_date, INTERVAL 6 MONTH);

-- Ans to Q10 How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?
ALTER TABLE album
ADD COLUMN ReleaseYear INTEGER;

-- Ans to Q11 Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. They want to know the average total amount spent by customers from each country, along with the number of customers and the average number of tracks purchased per customer. Write an SQL query to provide this information.

