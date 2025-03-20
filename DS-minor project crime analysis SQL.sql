create database crime;
use crime;
set SQL_SAFE_UPDATES =0;
select * from district_ipc_2001_2012; 
desc  district_ipc_2001_2012;
select * from district_crimes_against_women_2001_13;
create  table district_ipc_2001_2013;
create table district_ipc_2013;
create table district_ipc_2014;

# Q1 Annual Crime Trends: Compute the total number of victims per year and 
-- analyze any patterns or fluctuations in crime rates over the years.

SELECT YEAR, SUM(`TOTAL IPC CRIMES`) AS total_crimes
FROM district_ipc_2001_2013
GROUP BY YEAR
ORDER BY YEAR
LIMIT 0, 200;

-- 2. State-Wise Crime Analysis (2001-2012): Perform a comprehensive analysis of various
-- crimes recorded in each state over the given period. Identify trends, anomalies, and patterns.

 SELECT 
    `STATE/UT`,
    SUM(`MURDER`) AS total_murder,
    SUM(`ATTEMPT TO MURDER`) AS total_attempt_to_murder,
    SUM(`CULPABLE HOMICIDE NOT AMOUNTING TO MURDER`) AS total_culpable_homicide,
    SUM(`RAPE`) AS total_rape,
    SUM(`CUSTODIAL RAPE`) AS total_custodial_rape,
    SUM(`OTHER RAPE`) AS total_other_rape,
    SUM(`KIDNAPPING & ABDUCTION`) AS total_kidnapping_abduction,
    SUM(`ROBBERY`) AS total_robbery,
    SUM(`BURGLARY`) AS total_burglary,
    SUM(`THEFT`) AS total_theft,
    SUM(`RIOTS`) AS total_riots,
    SUM(`DOWRY DEATHS`) AS total_dowry_deaths,
    SUM(`ASSAULT ON WOMEN WITH INTENT TO OUTRAGE HER MODESTY`) AS total_assault_on_women,
    SUM(`CRUELTY BY HUSBAND OR HIS RELATIVES`) AS total_cruelty_by_husband,
    SUM(`OTHER IPC CRIMES`) AS total_other_ipc_crimes,
    SUM(`TOTAL IPC CRIMES`) AS total_ipc_crimes
FROM district_ipc_2001_2012
WHERE `YEAR` BETWEEN 2001 AND 2012
GROUP BY `STATE/UT`
ORDER BY total_ipc_crimes DESC;
 

-- 3. City-Wise Crime Distribution: For each state, 
-- identify the top six cities with the highest recorded crime incidents.

WITH RankedCities AS (
    SELECT 
        `STATE/UT`, 
        `DISTRICT`, 
        SUM(`TOTAL IPC CRIMES`) AS total_crimes,
        RANK() OVER (PARTITION BY `STATE/UT` ORDER BY SUM(`TOTAL IPC CRIMES`) DESC) AS crime_rank
    FROM district_ipc_2001_2013
    GROUP BY `STATE/UT`, `DISTRICT`
)
SELECT `STATE/UT`, `DISTRICT`, total_crimes
FROM RankedCities
WHERE crime_rank <= 6
ORDER BY `STATE/UT`, crime_rank;


-- 4. Highest Crime Rate States: Determine the top five states with the highest crime rates
-- across all crime categories.

SELECT `STATE/UT`, SUM(`TOTAL IPC CRIMES`) AS total_crimes
FROM district_ipc_2001_2012
GROUP BY `STATE/UT`
ORDER BY total_crimes DESC
LIMIT 5
;


-- 5. Crimes Against Women: Identify the top five cities with the
-- highest number of crimes committed against women.

SELECT `DISTRICT`, `STATE/UT`, 
       SUM(`Rape` + 
           `Kidnapping and Abduction` + 
           `Dowry Deaths` + 
           `Assault on women with intent to outrage her modesty` + 
           `Insult to modesty of Women` + 
           `Cruelty by Husband or his Relatives` + 
           `Importation of Girls`) AS Total_Crimes
FROM district_crimes_against_women_2001_13
WHERE `DISTRICT` NOT LIKE '%TOTAL%'  -- Excludes "TOTAL", "ZZ TOTAL", etc.
GROUP BY `DISTRICT`, `STATE/UT`
ORDER BY Total_Crimes DESC
LIMIT 5;

-- 6 


WITH RankedReasons AS (
    SELECT 
        `Area_Name`,  
        `Sub_Group_Name` AS `Reason`, 
        SUM(`K_A_Cases_Reported`) AS Total_Cases, 
        RANK() OVER (PARTITION BY `Area_Name` ORDER BY SUM(`K_A_Cases_Reported`) DESC) AS ranked_position
    FROM kidnapping_and_abduction
    WHERE `Group_Name` IN ('Kidnap - For Murder', 'Kidnap - For Other Reasons') 
    GROUP BY `Area_Name`, `Sub_Group_Name`
)
SELECT `Area_Name`, `Reason`, Total_Cases
FROM RankedReasons
WHERE ranked_position <= 3
ORDER BY `Area_Name`, ranked_position;



WITH RankedCities AS (
    SELECT 
        `STATE/UT` AS State, 
        DISTRICT AS City, 
        SUM(`TOTAL IPC CRIMES`) AS TotalCrimes,
        RANK() OVER (PARTITION BY `STATE/UT` ORDER BY SUM(`TOTAL IPC CRIMES`) DESC) AS Rank
    FROM crimes_data
    GROUP BY ` 
    
	
    STATE/UT`, DISTRICT
)
SELECT State, City, TotalCrimes
FROM district_crimes_committed_ipc_2001_2012
WHERE Rank <= 6
ORDER BY State, Rank;


-- 7Crime Pair Analysis: Identify the top ten pairs of crimes where one crime tends to lead to
   another (e.g., kidnapping leading to murder, custodial torture leading to custodial death, rape
    leading to murder, etc.).--

SELECT `DISTRICT`, `STATE/UT`, 
       SUM(`Rape` + `Kidnapping and Abduction` + `Dowry Deaths` + 
           `Assault on women with intent to outrage her modesty` + 
           `Insult to modesty of Women` + 
           `Cruelty by Husband or his Relatives` + 
           `Importation of Girls`) AS Total_Crimes
FROM district_crimes_against_women_2001_13
GROUP BY `DISTRICT`, `STATE/UT`
ORDER BY Total_Crimes ASC
LIMIT 5;

SELECT `DISTRICT`, `STATE/UT`, 
       SUM(COALESCE(`Rape`, 0) + 
           COALESCE(`Kidnapping and Abduction`, 0) + 
           COALESCE(`Dowry Deaths`, 0) + 
           COALESCE(`Assault on women with intent to outrage her modesty`, 0) + 
           COALESCE(`Insult to modesty of Women`, 0) + 
           COALESCE(`Cruelty by Husband or his Relatives`, 0) + 
           COALESCE(`Importation of Girls`, 0)) AS Total_Crimes
FROM district_crimes_against_women_2001_13
WHERE `DISTRICT` NOT IN ('STF', 'DISCOM', 'CID', 'SPL CELL')  -- Exclude non-districts
GROUP BY `DISTRICT`, `STATE/UT`
HAVING Total_Crimes > 0  -- Exclude districts with zero reported crimes
ORDER BY Total_Crimes ASC
LIMIT 5;

-- 8. Safest States for Women: Determine the top five states that are
-- statistically the safest for women, based on crime rates related to women’s safety.

WITH StateCrimeTotals AS (
    SELECT 
        `STATE/UT`,
        SUM(`Rape` + 
            `Kidnapping and Abduction` + 
            `Dowry Deaths` + 
            `Assault on women with intent to outrage her modesty` + 
            `Insult to modesty of Women` + 
            `Cruelty by Husband or his Relatives` + 
            `Importation of Girls`) AS Total_Crimes
    FROM district_crimes_against_women_2001_13
    GROUP BY `STATE/UT`
)
SELECT `STATE/UT`, Total_Crimes
FROM StateCrimeTotals
WHERE Total_Crimes > 0  -- Ensures we exclude states with missing data
ORDER BY Total_Crimes ASC
LIMIT 5; 

-- 9. Safest Cities for Women: Identify the top five cities with the lowest crime rates against women.

SELECT `DISTRICT`, `STATE/UT`,  
       SUM(`Rape` + `Kidnapping & Abduction` + `Dowry Deaths` +  
           `Assault on women with intent to outrage her modesty` +  
           `Insult to modesty of Women` + `Cruelty by Husband or his Relatives` +  
           `Importation of Girls`) AS Total_Crimes  
FROM district_crimes_against_women_2001_13  
WHERE `DISTRICT` NOT IN ('STF', 'CID', 'DISCOM', 'SPL CELL')  -- Exclude invalid districts  
GROUP BY `DISTRICT`, `STATE/UT`  
ORDER BY Total_Crimes ASC  
LIMIT 5;
-- 11. Socioeconomic Factors and Crime:
a. Analyze whether there is a correlation between a person’s salary and their likelihood
of engaging in criminal activities.
b. Examine how literacy rates influence the likelihood of an individual being involved in
crimes.


WITH CombinedData AS (
    SELECT 
        edu.`Area_Name`, 
        edu.`Year`, 
        edu.`Education_Illiterate`, 
        edu.`Education_Matric_or_Higher_Secondary_&_above`,
        edu.`Education_Total`, 
        eco.`Economic_Set_up_Annual_Income_upto_Rs_25000`,
        eco.`Economic_Set_up_Middle_income_from_50001_to_100000`,
        eco.`Economic_Set_up_Upper_income_above_Rs_300000`,
        eco.`Economic_Set_up_Total`
    FROM juveniles_arrested_education AS edu
    JOIN juveniles_eco_setup AS eco
    ON edu.`Area_Name` = eco.`Area_Name` AND edu.`Year` = eco.`Year`
)

-- Analyzing the correlation between salary and crime
SELECT 
    `Area_Name`, 
    `Year`,
    (Economic_Set_up_Annual_Income_upto_Rs_25000 * 100.0 / Economic_Set_up_Total) AS Low_Income_Percentage,
    (Economic_Set_up_Upper_income_above_Rs_300000 * 100.0 / Economic_Set_up_Total) AS High_Income_Percentage
FROM CombinedData
ORDER BY `Year`, `Area_Name`;

-- Analyzing the influence of literacy rates on crime
SELECT 
    `Area_Name`, 
    `Year`,
    (Education_Illiterate * 100.0 / Education_Total) AS Illiteracy_Rate,
    (Education_Matric_or_Higher_Secondary_&_above * 100.0 / Education_Total) AS Higher_Education_Rate
FROM CombinedData
ORDER BY `Year`, `Area_Name`;




WITH CombinedData AS (
    SELECT 
        `e.Area_Name`, 
        `e.Year`, 
        `e.Education_Illiterate`, 
        `e.Education_Matric_or_Higher_Secondary_&_above`,
        `e.Education_Total`, 
        `eco.Economic_Set_up_Annual_Income_upto_Rs_25000`,
        `eco.Economic_Set_up_Middle_income_from_50001_to_100000`,
        `eco.Economic_Set_up_Upper_income_above_Rs_300000`,
        `eco.Economic_Set_up_Total`
    FROM juveniles_arrested_education e
    JOIN juveniles_eco_setup eco
    ON e.Area_Name = eco.Area_Name AND e.Year = eco.Year
)
-- Analyzing the correlation between salary and crime
SELECT 
    `Area_Name`, 
    `Year`,
    (Economic_Set_up_Annual_Income_upto_Rs_25000 * 100.0 / Economic_Set_up_Total) AS Low_Income_Percentage,
    (Economic_Set_up_Upper_income_above_Rs_300000 * 100.0 / Economic_Set_up_Total) AS High_Income_Percentage
FROM CombinedData
ORDER BY Year, Area_Name;

-- Analyzing the influence of literacy rates on crime
SELECT 
    Area_Name, 
    Year,
    (Education_Illiterate * 100.0 / Education_Total) AS Illiteracy_Rate,
    (Education_Matric_or_Higher_Secondary_&_above * 100.0 / Education_Total) AS Higher_Education_Rate
FROM CombinedData
ORDER BY Year, Area_Name;


-- 12 Identify the top three reasons at the state level for juveniles (individuals under 18
-- years of age) being involved in crimes.

WITH RankedReasons AS (
    SELECT 
        `STATE/UT`, 
        `CRIME` AS `Reason`,
        SUM(`Grand total`) AS Total_Juveniles,
        RANK() OVER (PARTITION BY `STATE/UT` ORDER BY SUM(`Grand total`) DESC) AS `rank_value`
    FROM juvenile_ipc_and_ssl
    GROUP BY `STATE/UT`, `CRIME`
)
SELECT `STATE/UT`, `Reason`, Total_Juveniles
FROM RankedReasons
WHERE `rank_value` <= 3
ORDER BY `STATE/UT`, `rank_value`;

-- b.Determine the top ten states with the highest number of juvenile crime cases.

SELECT `STATE/UT`, SUM(`Grand total`) AS Total_Juvenile_Crimes
FROM juvenile_ipc_and_ssl
GROUP BY `STATE/UT`
ORDER BY Total_Juvenile_Crimes DESC
LIMIT 10;

-- 13. Crime Rate Trends Over Time: Calculate the rate of change in total crimes for each state
-- over the given timeline and identify states with significant increases or decreases.

WITH CrimeYearly AS (
    SELECT 
        `STATE/UT`, 
        `YEAR`, 
        SUM(`TOTAL IPC CRIMES`) AS total_crimes
    FROM district_ipc_2001_2013
    GROUP BY `STATE/UT`, `YEAR`
),
CrimeRateChange AS (
    SELECT 
        c1.`STATE/UT`, 
        c1.`YEAR` AS current_year,
        c1.total_crimes AS current_crimes,
        c2.total_crimes AS previous_crimes,
        ((c1.total_crimes - c2.total_crimes) / NULLIF(c2.total_crimes, 0)) * 100 AS crime_rate_change
    FROM CrimeYearly c1
    LEFT JOIN CrimeYearly c2
    ON c1.`STATE/UT` = c2.`STATE/UT` AND c1.`YEAR` = c2.`YEAR` + 1
)
SELECT * FROM CrimeRateChange
ORDER BY `STATE/UT`, current_year;


-- 14. Crime Distribution by State: Compute and visualize the percentage share of each type of
-- crime for all states to understand the distribution of criminal activities.

WITH StateTotalCrimes AS (
    SELECT 
        `STATE/UT`, 
        SUM(`TOTAL IPC CRIMES`) AS total_crimes
    FROM district_ipc_2001_2013
    GROUP BY `STATE/UT`
),
CrimePercentage AS (
    SELECT 
        c.`STATE/UT`,
        SUM(`MURDER`) * 100.0 / NULLIF(s.total_crimes, 0) AS murder_percentage,
        SUM(`RAPE`) * 100.0 / NULLIF(s.total_crimes, 0) AS rape_percentage,
        SUM(`KIDNAPPING & ABDUCTION`) * 100.0 / NULLIF(s.total_crimes, 0) AS kidnapping_percentage,
        SUM(`ROBBERY`) * 100.0 / NULLIF(s.total_crimes, 0) AS robbery_percentage,
        SUM(`BURGLARY`) * 100.0 / NULLIF(s.total_crimes, 0) AS burglary_percentage,
        SUM(`THEFT`) * 100.0 / NULLIF(s.total_crimes, 0) AS theft_percentage,
        SUM(`RIOTS`) * 100.0 / NULLIF(s.total_crimes, 0) AS riots_percentage,
        SUM(`DOWRY DEATHS`) * 100.0 / NULLIF(s.total_crimes, 0) AS dowry_deaths_percentage,
        SUM(`ASSAULT ON WOMEN WITH INTENT TO OUTRAGE HER MODESTY`) * 100.0 / NULLIF(s.total_crimes, 0) AS assault_on_women_percentage,
        SUM(`CRUELTY BY HUSBAND OR HIS RELATIVES`) * 100.0 / NULLIF(s.total_crimes, 0) AS cruelty_by_husband_percentage,
        SUM(`OTHER IPC CRIMES`) * 100.0 / NULLIF(s.total_crimes, 0) AS other_crimes_percentage
    FROM district_ipc_2001_2013 c
    JOIN StateTotalCrimes s ON c.`STATE/UT` = s.`STATE/UT`
    GROUP BY c.`STATE/UT`, s.total_crimes
)
SELECT * FROM CrimePercentage
ORDER BY `STATE/UT`;