--1. Первинний перегляд структури даних
SELECT * 
FROM cohort_users_raw 
LIMIT 10; 

--2. Видалення зайвих пробілів на початку та наприкінці текстового рядка
SELECT 
    signup_datetime,
    TRIM(signup_datetime) --очистка лівих і правих пробілів
FROM cohort_users_raw;

--3. Редагування дати (видалення часу за допомогою розділювача пробілу)
SELECT 
    signup_datetime,
    split_part(TRIM(signup_datetime), ' ',1) --відрізання часу
FROM cohort_users_raw;

--4. Стандартизація делімітерів: заміна символів "/" та "." на уніфікований дефіс "-"
SELECT 
    signup_datetime,
    REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g')
FROM cohort_users_raw;

--5. Обробка двозначного формату року (YY) та приведення текстового рядка до типу DATE
-- Перевірка довжини року (3-тя позиція після розділення). Якщо рік містить 2 символи, додається префікс '20'.
SELECT
     signup_datetime,
     REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'),
    CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||  
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' || 
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3) 
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g') 
     END
FROM cohort_users_raw;

-- Конвертація обробленого рядка у тип DATE за шаблоном 'DD-MM-YYYY'
SELECT
     signup_datetime,
     REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'),
     TO_DATE(
     CASE WHEN length(split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)) = 2 
        THEN split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 1) || '-' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 2) || '-20' ||
             split_part(REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g'), '-', 3)
        ELSE REGEXP_REPLACE((split_part(TRIM(signup_datetime), ' ',1)), '[/.]', '-', 'g')
     END, 'DD-MM-YYYY') AS signup_ts 
FROM cohort_users_raw;

--СТЕ 1. Формування базового набору даних користувачів із валідованою датою реєстрації

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


--СТЕ 2. Формування набору даних активності (трансформація дат аналогічна до CTE 1)

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

--JOIN СТЕ 3. Об'єднання таблиць, розрахунок місячного інтервалу та очищення від NULL-значень і тестів

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
    date_trunc('month', signup_ts)::date AS cohort_month,
    date_trunc('month', event_ts)::date AS activity_month,
    EXTRACT(MONTH FROM age(date_trunc('month',event_ts), date_trunc('month', signup_ts))) AS month_offset 
FROM users_parsed u
JOIN event_parsed e
ON u.user_id=e.user_id
WHERE signup_ts IS NOT NULL 
    AND event_ts IS NOT NULL
    AND event_type IS NOT NULL
    AND event_type <> 'test_event';

-- Фінальний агрегований запит для побудови матриці утримання

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
    date_trunc('month', signup_ts)::date AS cohort_month,
    date_trunc('month', event_ts)::date AS activity_month
    EXTRACT(MONTH FROM age(date_trunc('month',event_ts), date_trunc('month', signup_ts))) AS month_offset
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
