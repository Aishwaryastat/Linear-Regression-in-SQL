# create database
create database linear_regression;
# use database
use linear_regression;
# create table
create table student_study(
number_courses int, 
time_study int,
Marks int)
;
# Display or select data
select * from student_study;

# Univariate Analysis
select count(marks) as Total_student,
		count(distinct marks) as cardinality,
        min(marks) as minimum_marks, max(marks) as maximum_marks,
        max(marks)-min(marks) as range_of_marks,
        avg(marks) as Average_mark,
        stddev(marks) as standard_deviation_of_marks
from student_study;
        
with histogram(value,frequency) as (
select marks, count(*)
from student_study
group by marks)
select (1.0 * sum(value*frequency))/sum(frequency) as mean
from histogram;

with nhistogram(value,prob) as 
(select marks, sum(1.0/total)
from student_study,(select count(*) as total from student_study ) as temp 
group by marks)
select sum(value*prob) as mean
from nhistogram;

# Mode
with histogram as 
(select marks as val , count(*) as freq 
from student_study
group by marks)
select val from histogram, 
(select max(freq) as top from histogram) as T
where freq= top;

select marks, count(*) as freq
FROM student_study
GROUP BY marks
ORDER BY freq DESC
LIMIT 1;

# Median 
SELECT
    AVG(marks) AS median
FROM (
    SELECT
        marks,
        @rownum := @rownum + 1 AS rownum,
        (SELECT COUNT(*) FROM student_study) AS total_rows
    FROM (
        SELECT marks
        FROM student_study
        ORDER BY marks
    ) AS sorted_marks,
    (SELECT @rownum := 0) AS rownum_init
) AS ranked
WHERE
    rownum = CEIL(total_rows / 2) OR
    rownum = FLOOR(total_rows / 2) + 1;

# Skewness
SELECT
    SUM(POW(marks - avg_marks, 3)) / ((COUNT(*) - 1) * POW(std_marks, 3)) AS skewness
FROM
    student_study
CROSS JOIN
    (SELECT AVG(marks) AS avg_marks, STDDEV(marks) AS std_marks FROM student_study) AS stats;
# Kurtosis 
SELECT SUM(POW(marks - mean, 4)) / COUNT(*) / POW(SUM(POW(marks - mean, 2)) / (COUNT(*) - 1), 1 / 3) AS kurtosis
FROM student_study, (SELECT AVG(marks) AS mean FROM student_study) AS mean_subquery;

# correlation
select (avg(marks*time_study)-avg(marks)*avg(time_study))/(std(marks)*std(time_study))*100 as correlation from student_study;

select (avg(marks*number_courses)-avg(marks)*avg(number_courses))/(std(marks)*std(number_courses))*100 as correlation from student_study;

# Missing data
select count(*) from student_study where marks is null;
select count(*) from student_study where number_courses is null;
select count(*) from student_study where time_study is null;

# outlier 
with orderedList AS (
SELECT
	marks,
	ROW_NUMBER() OVER (ORDER BY marks) AS row_n
FROM student_study
),
iqr AS (
SELECT
	marks,
	(
		SELECT marks AS quartile_break
		FROM orderedList
		WHERE row_n = FLOOR((SELECT COUNT(*)
			FROM student_study)*0.75)
			) AS q_three,
	(
		SELECT marks AS quartile_break
		FROM orderedList
		WHERE row_n = FLOOR((SELECT COUNT(*)
			FROM student_study)*0.25)
			) AS q_one,
	1.5 * ((
		SELECT marks AS quartile_break
		FROM orderedList
		WHERE row_n = FLOOR((SELECT COUNT(*)
			FROM student_study)*0.75)
			) - (
			SELECT marks AS quartile_break
			FROM orderedList
			WHERE row_n = FLOOR((SELECT COUNT(*)
				FROM student_study)*0.25)
			)) AS outlier_range
	FROM orderedList
)

SELECT marks
FROM iqr
WHERE marks >= ((SELECT MAX(q_three)
	FROM iqr) +
	(SELECT MAX(outlier_range)
		FROM iqr)) OR
		marks <= ((SELECT MAX(q_one)
	FROM iqr) -
	(SELECT MAX(outlier_range)
		FROM iqr))
;

# Linear regression 
SELECT
    (sum_x1y - mean_x1 * mean_y * n) / (sum_x1_squared - POW(mean_x1, 2) * n) AS beta_1,
    (sum_x2y - mean_x2 * mean_y * n) / (sum_x2_squared - POW(mean_x2, 2) * n) AS beta_2,
    mean_y - ((sum_x1y - mean_x1 * mean_y * n) / (sum_x1_squared - POW(mean_x1, 2) * n)) * mean_x1 - ((sum_x2y - mean_x2 * mean_y * n) / (sum_x2_squared - POW(mean_x2, 2) * n)) * mean_x2 AS beta_0
FROM (
    SELECT
        SUM(number_courses * time_study) AS sum_x1y,
        SUM(time_study * marks) AS sum_x2y,
        SUM(number_courses * number_courses) AS sum_x1_squared,
        SUM(time_study * time_study) AS sum_x2_squared,
        AVG(number_courses) AS mean_x1,
        AVG(time_study) AS mean_x2,
        AVG(marks) AS mean_y,
        COUNT(*) AS n
    FROM student_study
) AS subquery;

# Prediction
SET @x1_value = 4;
SET @x2_value = 7;
SET @beta_0 = 177.56;
SET @beta_1 = -33.25;
SET @beta_2 = 5.56;

-- Calculate the prediction
SELECT @beta_0 + (@beta_1 * @x1_value) + (@beta_2 * @x2_value) AS predicted_y;
