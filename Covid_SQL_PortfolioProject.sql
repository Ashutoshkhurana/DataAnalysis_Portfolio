-- COVID-19 Data Analysis SQL Queries [Portfolio Project]
-- Author: ASHUTOSH KHURANA
-- Purpose: Comprehensive analysis of COVID-19 data to derive insights on infection rates, mortality, and vaccination progress
-- Data Sources: CovidDeaths and CovidVaccinations tables (Data extracted from ourworldindata.org)
--NOTE: DATA TILL 7TH MARCH 2023

-- BASIC SQL QUERIES

-- 1. Death Rate Analysis for a specific country
-- Objective: Track the progression of COVID-19 mortality rate in a Country over time

SELECT location, date, "CovidDeaths".total_cases,
       "CovidDeaths".total_deaths,
       ("CovidDeaths".total_deaths/"CovidDeaths".total_cases)* 100 AS DeathPercent
FROM "CovidDeaths"
WHERE location = 'India'
ORDER BY 1,2;

-- 2. Infection Rate Analysis for India
-- Objective: Examine the spread of COVID-19 in a country relative to its population
SELECT location, date, population,
       "CovidDeaths".total_cases,
       ("CovidDeaths".total_cases/"CovidDeaths".population)* 100 AS InfectionPercent
FROM "CovidDeaths"
WHERE location = 'India'
ORDER BY 1,2;

-- 3. Global Highest Infection Rate Comparison
-- Objective: Identify countries with the highest infection rates relative to their population (As of the last date in the data)
SELECT location, population,
       MAX("CovidDeaths".total_cases) AS Highestinfection,
       MAX(("CovidDeaths".total_cases/"CovidDeaths".population))* 100 AS InfectionPercent
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionPercent DESC ;

-- 4. Country-wise Death Toll Analysis
-- Objective: Rank countries by their total COVID-19 death count
SELECT location, MAX(total_deaths) AS HighestDeaths
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

-- 5. Continental and Income Group Death Toll Analysis
-- Objective: Analyze death counts by continent and income groups
SELECT location, MAX(total_deaths) AS HighestDeaths
FROM "CovidDeaths"
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;

-- 6. Global Daily COVID-19 Statistics
-- Objective: Track daily new cases, deaths, and calculate the daily global death rate
SELECT "CovidDeaths".date,
       SUM("CovidDeaths".new_cases) AS totalCases,
       SUM(new_deaths) AS totaldeaths,
       (SUM(new_deaths)/ SUM("CovidDeaths".new_cases))*100 AS deathrate
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY date;

-- 7. Overall Global COVID-19 Statistics
-- Objective: Calculate the overall global COVID-19 cases, deaths, and mortality rate
SELECT SUM(public."CovidDeaths".new_cases) AS totalCases,
       SUM(public."CovidDeaths".new_deaths) AS totaldeaths,
       (SUM(public."CovidDeaths".new_deaths)/ SUM(public."CovidDeaths".new_cases))*100 AS deathrate
FROM public."CovidDeaths"
WHERE public."CovidDeaths".continent IS NOT NULL;

-- Data Preparation: Formatting the Date Column
-- Note: Ensuring consistent date format is crucial for accurate time-based analysis

ALTER TABLE "CovidVaccinations"
ALTER COLUMN date TYPE date
USING to_date(date, 'DD-MM-YYYY');

--- Advanced SQL QUERIES

-- 8. Vaccination Progress Analysis Using CTE
-- Objective: Track the progress of vaccination rollout across different locations

WITH pop_vax (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
    AS (SELECT cd.continent,
               cd.location,
               cd.date,
               cd.population,
               cv.new_vaccinations,
               SUM(cv.new_vaccinations)
               OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Cumulative_vaccinations
        FROM "CovidDeaths" cd
                 JOIN "CovidVaccinations" cv
                      ON cd.location = cv.location AND cd.date = cv.date
        WHERE cd.continent is not null
        )
SELECT *, (cumulative_vaccinations / population) * 100 AS percentage_vaccinated
FROM pop_vax
ORDER BY 2,3;

-- 9. Vaccination Analysis Using Temporary Table
-- Objective: Provide a flexible structure for further analysis of vaccination data
DROP TABLE IF EXISTS VaccinatedPercentage;
CREATE TABLE VaccinatedPercentage
(
    continent varchar(255),
    location varchar(255),
    date timestamp,
    population numeric,
    new_vaccinations numeric,
    cumulative_vaccinations numeric
);

INSERT INTO VaccinatedPercentage
    SELECT cd.continent,
               cd.location,
               cd.date,
               cd.population,
               cv.new_vaccinations,
               SUM(cv.new_vaccinations)
               OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Cumulative_vaccinations
        FROM "CovidDeaths" cd
                 JOIN "CovidVaccinations" cv
                      ON cd.location = cv.location AND cd.date = cv.date;

SELECT *, (cumulative_vaccinations/VaccinatedPercentage.population)*100 AS percentage_vaccinated
FROM VaccinatedPercentage
WHERE continent IS NOT NULL
ORDER BY 2,3;

-- 10. Creating a View for Percentage of People Vaccinated
-- Objective: Establish a reusable view for ongoing vaccination analysis
-- Can be further used to create dashboards

CREATE VIEW Percentage_people_vaccinated AS
    SELECT cd.continent,
               cd.location,
               cd.date,
               cd.population,
               cv.new_vaccinations,
               SUM(cv.new_vaccinations)
               OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Cumulative_vaccinations
        FROM "CovidDeaths" cd
                 JOIN "CovidVaccinations" cv
                      ON cd.location = cv.location AND cd.date = cv.date
        WHERE cd.continent is not null;

