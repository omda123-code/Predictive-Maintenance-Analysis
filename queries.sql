use Predictive
select * from ai4i2020

-- Q1: What does the dataset look like?
-- Purpose: Preview the first few records to understand the structure
SELECT TOP 10 * 
FROM ai4i2020;

-- Q2: How many total records and how many failures?
-- Purpose: To check dataset balance and failure frequency
SELECT 
    COUNT(*) AS Total_Records,
    SUM(Machine_failure) AS Total_Failures,
    CAST(SUM(Machine_failure) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate_Percent
FROM ai4i2020;

-- Q3: Which product type fails more often?
-- Purpose: Identify high-risk machine types
SELECT 
    Type,
    COUNT(*) AS Total,
    SUM(Machine_failure) AS Failures,
    CAST(SUM(Machine_failure) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate
FROM ai4i2020
GROUP BY Type
ORDER BY Failure_Rate DESC;

-- Q4: Does higher process temperature increase failure likelihood?
-- Purpose: Explore potential predictive variable
SELECT 
    CASE 
        WHEN Process_temperature_K < 305 THEN 'Low'
        WHEN Process_temperature_K BETWEEN 305 AND 315 THEN 'Normal'
        ELSE 'High'
    END AS Temp_Range,
    COUNT(*) AS Total,
    SUM(Machine_failure) AS Failures,
    CAST(SUM(Machine_failure)*100.0/COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN Process_temperature_K < 305 THEN 'Low'
        WHEN Process_temperature_K BETWEEN 305 AND 315 THEN 'Normal'
        ELSE 'High'
    END
ORDER BY Failure_Rate DESC;

-- Q5: How does torque and rotational speed impact failures?
-- Purpose: Detect mechanical stress patterns
SELECT 
    AVG(Torque_Nm) AS Avg_Torque,
    AVG(Rotational_speed_rpm) AS Avg_RPM,
    SUM(Machine_failure) AS Failures
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN Machine_failure = 1 THEN 'Failure'
        ELSE 'No Failure'
    END;

-- Q6: Which failure types (TWF, HDF, etc.) occur most often?
-- Purpose: Determine the most frequent failure category
SELECT 
    SUM(TWF) AS Tool_Wear_Failure,
    SUM(HDF) AS Heat_Dissipation_Failure,
    SUM(PWF) AS Power_Failure,
    SUM(OSF) AS Overstrain_Failure,
    SUM(RNF) AS Random_Failure
FROM ai4i2020;

-- Q7: Which machines have the highest tool wear?
-- Purpose: Identify potential maintenance candidates
SELECT TOP 10 
    Product_ID, Tool_wear_min, Machine_failure
FROM ai4i2020
ORDER BY Tool_wear_min DESC;

-- Q8: What is the average air and process temperature for failed vs non-failed machines?
-- Purpose: To understand how temperature differences may correlate with machine failures
SELECT 
    Machine_failure,
    AVG(Air_temperature_K) AS Avg_Air_Temp,
    AVG(Process_temperature_K) AS Avg_Process_Temp,
    AVG(Process_temperature_K - Air_temperature_K) AS Avg_Temp_Diff
FROM ai4i2020
GROUP BY Machine_failure;


-- Q9: What are the correlations between torque, rotational speed, and tool wear?
-- Purpose: Detect operational stress factors that may lead to failure
WITH Stats AS (
    SELECT
        CAST(Torque_Nm AS FLOAT) AS Torque_Nm,
        CAST(Rotational_speed_rpm AS FLOAT) AS Rotational_speed_rpm,
        CAST(Tool_wear_min AS FLOAT) AS Tool_wear_min,
        CAST(AVG(Torque_Nm) OVER() AS FLOAT) AS avg_torque,
        CAST(AVG(Rotational_speed_rpm) OVER() AS FLOAT) AS avg_rpm,
        CAST(AVG(Tool_wear_min) OVER() AS FLOAT) AS avg_wear
    FROM ai4i2020
)
SELECT
    CAST(
        SUM((Torque_Nm - avg_torque) * (Rotational_speed_rpm - avg_rpm)) 
        / 
        SQRT(SUM(POWER(Torque_Nm - avg_torque, 2)) * SUM(POWER(Rotational_speed_rpm - avg_rpm, 2)))
        AS DECIMAL(5,3)
    ) AS Corr_Torque_RPM,
    CAST(
        SUM((Torque_Nm - avg_torque) * (Tool_wear_min - avg_wear)) 
        / 
        SQRT(SUM(POWER(Torque_Nm - avg_torque, 2)) * SUM(POWER(Tool_wear_min - avg_wear, 2)))
        AS DECIMAL(5,3)
    ) AS Corr_Torque_Wear,
    CAST(
        SUM((Rotational_speed_rpm - avg_rpm) * (Tool_wear_min - avg_wear)) 
        / 
        SQRT(SUM(POWER(Rotational_speed_rpm - avg_rpm, 2)) * SUM(POWER(Tool_wear_min - avg_wear, 2)))
        AS DECIMAL(5,3)
    ) AS Corr_RPM_Wear
FROM Stats;


-- Q10: How does tool wear vary across different product types?
-- Purpose: Identify if certain product types experience higher tool degradation
SELECT 
    Type,
    AVG(Tool_wear_min) AS Avg_Tool_Wear,
    MAX(Tool_wear_min) AS Max_Tool_Wear,
    MIN(Tool_wear_min) AS Min_Tool_Wear
FROM ai4i2020
GROUP BY Type
ORDER BY Avg_Tool_Wear DESC;


-- Q11: Does high torque always mean a higher chance of failure?
-- Purpose: Group machines by torque levels to check failure rate
SELECT 
    CASE 
        WHEN Torque_Nm < 30 THEN 'Low Torque'
        WHEN Torque_Nm BETWEEN 30 AND 50 THEN 'Medium Torque'
        ELSE 'High Torque'
    END AS Torque_Level,
    COUNT(*) AS Total,
    SUM(Machine_failure) AS Failures,
    CAST(SUM(Machine_failure)*100.0/COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN Torque_Nm < 30 THEN 'Low Torque'
        WHEN Torque_Nm BETWEEN 30 AND 50 THEN 'Medium Torque'
        ELSE 'High Torque'
    END
ORDER BY Failure_Rate DESC;


-- Q12: What is the distribution of failure types among total failures?
-- Purpose: Compare the proportions of each specific failure category
SELECT 
    CAST(SUM(TWF) * 100.0 / SUM(Machine_failure) AS DECIMAL(5,2)) AS ToolWear_Failure_Percent,
    CAST(SUM(HDF) * 100.0 / SUM(Machine_failure) AS DECIMAL(5,2)) AS HeatDissipation_Failure_Percent,
    CAST(SUM(PWF) * 100.0 / SUM(Machine_failure) AS DECIMAL(5,2)) AS Power_Failure_Percent,
    CAST(SUM(OSF) * 100.0 / SUM(Machine_failure) AS DECIMAL(5,2)) AS OverStrain_Failure_Percent,
    CAST(SUM(RNF) * 100.0 / SUM(Machine_failure) AS DECIMAL(5,2)) AS Random_Failure_Percent
FROM ai4i2020
WHERE Machine_failure = 1;


-- Q13: Which operating conditions lead to simultaneous multiple failure types?
-- Purpose: Identify complex or compounded failure events
SELECT 
    UDI,
    Product_ID,
    (TWF + HDF + PWF + OSF + RNF) AS Failure_Types_Count
FROM ai4i2020
WHERE (TWF + HDF + PWF + OSF + RNF) > 1
ORDER BY Failure_Types_Count DESC;


-- Q14: Analyze combined impact of temperature difference and torque on failures
-- Purpose: Multi-variable segmentation analysis
SELECT 
    CASE 
        WHEN (Process_temperature_K - Air_temperature_K) < 5 THEN 'Low ΔT'
        WHEN (Process_temperature_K - Air_temperature_K) BETWEEN 5 AND 10 THEN 'Moderate ΔT'
        ELSE 'High ΔT'
    END AS Temp_Diff_Range,
    CASE 
        WHEN Torque_Nm < 30 THEN 'Low Torque'
        WHEN Torque_Nm BETWEEN 30 AND 50 THEN 'Medium Torque'
        ELSE 'High Torque'
    END AS Torque_Range,
    COUNT(*) AS Total,
    SUM(Machine_failure) AS Failures,
    CAST(SUM(Machine_failure)*100.0/COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN (Process_temperature_K - Air_temperature_K) < 5 THEN 'Low ΔT'
        WHEN (Process_temperature_K - Air_temperature_K) BETWEEN 5 AND 10 THEN 'Moderate ΔT'
        ELSE 'High ΔT'
    END,
    CASE 
        WHEN Torque_Nm < 30 THEN 'Low Torque'
        WHEN Torque_Nm BETWEEN 30 AND 50 THEN 'Medium Torque'
        ELSE 'High Torque'
    END
ORDER BY Failure_Rate DESC;


-- Q15: Which product IDs have the highest frequency of failures?
-- Purpose: Identify machines that repeatedly fail (potential maintenance targets)
SELECT 
    Product_ID,
    COUNT(*) AS Total_Records,
    SUM(Machine_failure) AS Failure_Count,
    CAST(SUM(Machine_failure)*100.0/COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate
FROM ai4i2020
GROUP BY Product_ID
HAVING SUM(Machine_failure) > 0
ORDER BY Failure_Rate DESC;


-- Q16: What is the relationship between machine age (tool wear) and failure type occurrence?
-- Purpose: Understand at which wear levels different failures appear
SELECT 
    CASE 
        WHEN Tool_wear_min < 50 THEN 'Low Wear'
        WHEN Tool_wear_min BETWEEN 50 AND 150 THEN 'Moderate Wear'
        ELSE 'High Wear'
    END AS Wear_Level,
    SUM(TWF) AS Tool_Wear_Failures,
    SUM(HDF) AS Heat_Failures,
    SUM(PWF) AS Power_Failures,
    SUM(OSF) AS Overstrain_Failures,
    SUM(RNF) AS Random_Failures
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN Tool_wear_min < 50 THEN 'Low Wear'
        WHEN Tool_wear_min BETWEEN 50 AND 150 THEN 'Moderate Wear'
        ELSE 'High Wear'
    END
ORDER BY Wear_Level;


-- Q17: Is there any correlation between rotational speed and temperature difference?
-- Purpose: Investigate if speed increases internal heating and stress
SELECT 
    CAST(AVG(Rotational_speed_rpm) AS DECIMAL(10,2)) AS Avg_RPM,
    CAST(AVG(Process_temperature_K - Air_temperature_K) AS DECIMAL(10,2)) AS Avg_Temp_Diff,
    CASE 
        WHEN Machine_failure = 1 THEN 'Failure'
        ELSE 'No Failure'
    END AS Status
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN Machine_failure = 1 THEN 'Failure'
        ELSE 'No Failure'
    END;


-- Q18: Create a failure severity score (custom metric)
-- Purpose: Build a composite indicator for maintenance prioritization
SELECT 
    UDI,
    Product_ID,
    (Torque_Nm * 0.3 + Rotational_speed_rpm * 0.1 + Tool_wear_min * 0.6) AS Failure_Severity_Score,
    Machine_failure
FROM ai4i2020
ORDER BY Failure_Severity_Score DESC;


-- Q19: Average severity score for each product type
-- Purpose: Compare operational risk across product categories
WITH Severity AS (
    SELECT 
        Type,
        (Torque_Nm * 0.3 + Rotational_speed_rpm * 0.1 + Tool_wear_min * 0.6) AS Score
    FROM ai4i2020
)
SELECT 
    Type,
    AVG(Score) AS Avg_Severity_Score
FROM Severity
GROUP BY Type
ORDER BY Avg_Severity_Score DESC;


-- Q20: Seasonal effect simulation using air temperature bands
-- Purpose: Analyze if ambient temperature indirectly impacts failures
SELECT 
    CASE 
        WHEN Air_temperature_K < 295 THEN 'Cold'
        WHEN Air_temperature_K BETWEEN 295 AND 305 THEN 'Moderate'
        ELSE 'Hot'
    END AS Ambient_Condition,
    COUNT(*) AS Total,
    SUM(Machine_failure) AS Failures,
    CAST(SUM(Machine_failure)*100.0/COUNT(*) AS DECIMAL(5,2)) AS Failure_Rate
FROM ai4i2020
GROUP BY 
    CASE 
        WHEN Air_temperature_K < 295 THEN 'Cold'
        WHEN Air_temperature_K BETWEEN 295 AND 305 THEN 'Moderate'
        ELSE 'Hot'
    END
ORDER BY Failure_Rate DESC;
