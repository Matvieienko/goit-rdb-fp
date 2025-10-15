CREATE SCHEMA pandemic;
USE pandemic;

SELECT * FROM infectious_cases;

-- 2
-- Створення таблиці країн
CREATE TABLE countries(
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(8) UNIQUE,
    country VARCHAR(32) NOT NULL UNIQUE
);

-- Заповнення країнами та кодами з infectious_cases
INSERT INTO countries (code, country)
SELECT DISTINCT Code, Entity 
FROM infectious_cases;

-- Додаємо зв’язок
ALTER TABLE infectious_cases
ADD COLUMN country_id INT,
ADD CONSTRAINT fk_country
    FOREIGN KEY (country_id)
    REFERENCES countries(id);

-- Заповнення country_id
SET SQL_SAFE_UPDATES = 0;    

UPDATE infectious_cases ic
JOIN countries c
    ON ic.Entity = c.country AND ic.Code = c.code
SET ic.country_id = c.id;

SET SQL_SAFE_UPDATES = 1;

-- Видалення дублюючих колонок
ALTER TABLE infectious_cases
DROP COLUMN Entity,
DROP COLUMN Code;

-- Підрахунок рядків
SELECT COUNT(*) FROM infectious_cases;

-- 3
SELECT
    ic.country_id,
    c.country AS entity,
    c.code AS code,
    AVG(CAST(ic.Number_rabies AS FLOAT)) AS avgCases_rabies,
    MIN(CAST(ic.Number_rabies AS FLOAT)) AS minCases_rabies,
    MAX(CAST(ic.Number_rabies AS FLOAT)) AS maxCases_rabies,
    SUM(CAST(ic.Number_rabies AS FLOAT)) AS sumCases_rabies
FROM infectious_cases ic
JOIN countries c ON ic.country_id = c.id
WHERE ic.Number_rabies IS NOT NULL
  AND ic.Number_rabies <> ''
  AND ic.Number_rabies != 'NULL'
GROUP BY ic.country_id, c.country, c.code
ORDER BY avgCases_rabies DESC
LIMIT 10;

-- 4
SELECT
    Year,
    STR_TO_DATE(CONCAT(Year, '-01-01'), '%Y-%m-%d') AS year_date,
    CURDATE() AS today_date,
    TIMESTAMPDIFF(YEAR, STR_TO_DATE(CONCAT(Year, '-01-01'), '%Y-%m-%d'), CURDATE()) AS years_diff
FROM infectious_cases;

-- 5
-- 5.1 Функція різниці в роках
DELIMITER //

CREATE FUNCTION diff_years(year INT) RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(CONCAT(year, '-01-01'), '%Y-%m-%d'),
        CURDATE()
    );
END //

DELIMITER ;

-- Використання
SELECT Year, diff_years(Year) AS years_diff
FROM infectious_cases;

-- 5.2. Функція середньої кількості захворювань за період
DELIMITER //

CREATE FUNCTION avg_cases_by_period(cases VARCHAR(16), period INT) RETURNS FLOAT
DETERMINISTIC
BEGIN
    IF cases IS NULL OR cases = '' OR cases = 'NULL' THEN
        RETURN NULL;
    ELSE
        RETURN CAST(cases AS FLOAT) / period;
    END IF;
END //

DELIMITER ;

-- Використання (наприклад, середня кількість випадків сказу на місяць):
SELECT
    Year,
    Number_rabies,
    avg_cases_by_period(Number_rabies, 12) AS rabies_avg_per_month
FROM infectious_cases
WHERE Number_rabies IS NOT NULL
  AND Number_rabies <> ''
  AND Number_rabies != 'NULL';
