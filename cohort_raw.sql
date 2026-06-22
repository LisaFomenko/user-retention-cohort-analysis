--1
SELECT * 
FROM cohort_users_raw 
LIMIT 10; 

--2
SELECT 
    signup_datetime,
    TRIM(signup_datetime) --очистка лівих і правих пробілів
FROM cohort_users_raw;

--3
SELECT 
    signup_datetime,
    split_part(TRIM(signup_datetime), ' ',1) --відрізання часу
FROM cohort_users_raw;

--4
SELECT 
    signup_datetime,
    REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g') --регулярний вирз для заміни "/" і "." на "-"
FROM cohort_users_raw;

--5
SELECT
     signup_datetime,
     REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'),
    CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 --відділення року від дати, якщо містить 2 символи, то
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||  --відділення дня + "-" +
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' || --відділення місяця + "-20" +
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3) --відділення року
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g') --в іншому випадку повернути це саме значення
     END
FROM cohort_users_raw;

SELECT
     signup_datetime,
     REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'),
     TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS signup_ts --перетворення в дату
FROM cohort_users_raw;

--СТЕ 1

SELECT
    user_id,
    signup_datetime,
    promo_signup_flag,
    TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS signup_ts
FROM cohort_users_raw;


--СТЕ 2 (перетворення дати аналогічно до СТЕ 1)

SELECT 
    user_id,
    event_type,
    TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS event_ts
FROM cohort_events_raw;

--JOIN СТЕ 3

WITH users_parsed AS(
SELECT
    user_id,
    signup_datetime,
    promo_signup_flag,
    TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS signup_ts
FROM cohort_users_raw),
event_parsed AS (
SELECT 
    user_id,
    event_type,
    TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS event_ts
FROM cohort_events_raw)
SELECT
    u.user_id,
    u.promo_signup_flag,
    date_trunc('month', signup_ts)::date AS cohort_month, --округлення до місяця і перетворення в дату без часу
    date_trunc('month', event_ts)::date AS activity_month,--округлення до місяця і перетворення в дату без часу
    EXTRACT(MONTH FROM age(date_trunc('month',event_ts), date_trunc('month', signup_ts))) AS month_offset --вдиділення року з обох дат, різниця між ними і перерахунок в місяці + виділення місяців з дат, їх різниця
FROM users_parsed u
JOIN event_parsed e
ON u.user_id=e.user_id
WHERE signup_ts IS NOT NULL 
    AND event_ts IS NOT NULL
    AND event_type IS NOT NULL
    AND event_type <> 'test_event';

-- фінальний запит

WITH users_parsed AS(
SELECT
    user_id,
    signup_datetime,
    promo_signup_flag,
    TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS signup_ts
FROM cohort_users_raw),
event_parsed AS (
SELECT 
    user_id,
    event_type,
    TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(event_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS event_ts
FROM cohort_events_raw),
user_activity AS (
SELECT
    u.user_id,
    u.promo_signup_flag,
    date_trunc('month', signup_ts)::date AS cohort_month, --округлення до місяця і перетворення в дату без часу
    date_trunc('month', event_ts)::date AS activity_month,--округлення до місяця і перетворення в дату без часу
    EXTRACT(MONTH FROM age(date_trunc('month',event_ts), date_trunc('month', signup_ts))) AS month_offset --знаходження різниці між датами в місяцях
FROM users_parsed u
JOIN event_parsed e
ON u.user_id=e.user_id
WHERE signup_ts IS NOT NULL 
    AND event_ts IS NOT NULL
    AND event_type IS NOT NULL
    AND event_type <> 'test_event')
SELECT 
    promo_signup_flag,
    cohort_month,
    month_offset,
    count(DISTINCT user_id) AS user_total
FROM user_activity
WHERE activity_month BETWEEN '2025-01-01' AND '2025-06-01'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;