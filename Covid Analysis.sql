SELECT * 
FROM Sarah.coviddeaths c 
WHERE continent is not null
ORDER BY 3,4;

-- SELECT * 
-- FROM Sarah.covidvaccinations c 
-- ORDER BY 3,4

-- SELECT DATA THAT WE ARE GOING TO BE USING

SELECT Location, 
date AS 'Date', 
total_cases AS 'Total Cases', 
new_cases AS 'New Cases', 
total_deaths AS 'Total Deaths', 
population AS 'Population'
FROM Sarah.coviddeaths c
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths 
-- Shows liklihood of dying if you contract covid in your country

SELECT Location, 
date AS 'Date', 
total_cases AS 'Total Cases',  
total_deaths AS 'Total Deaths',
(total_deaths/total_cases)*100 AS 'Total Deaths % (Raw Data)',
ROUND ((total_deaths/total_cases)*100, 2)AS 'Total Deaths %'
FROM Sarah.coviddeaths c
WHERE location like '%states%'
AND continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of Population got Covid

SELECT Location, 
date AS 'Date', 
population AS 'Population',
total_cases AS 'Total Cases',
(total_cases/population)*100 AS 'Population Infected % (Raw Data)',
ROUND ((total_deaths/total_cases)*100, 2)AS 'Population Infected %'
FROM Sarah.coviddeaths c
-- WHERE location like '%states%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT 
  location, 
  population AS 'Population',
  MAX(total_cases) AS 'Highest Infection Count',
  MAX((total_cases / population) * 100) AS 'Population Infected % (Raw Data)',
  ROUND(MAX((total_cases / population) * 100), 2) AS 'Population Infected %'
FROM 
  Sarah.coviddeaths
-- WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY 5 DESC

-- Showing Countries with Highest Death Count per Population 

SELECT 
  location, 
  MAX(CAST(total_deaths AS SIGNED)) AS 'Total Death Count'
FROM Sarah.coviddeaths
-- WHERE location LIKE '%states%'
WHERE continent is not null
AND location NOT IN ('World', 'European Union', 'International', 'Asia', 'Europe', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY `Total Death Count` DESC

-- Showing Continents with the Highest Death Count per Population 

SELECT continent, 
       SUM(CAST(REPLACE(Total_deaths, ',', '') AS SIGNED)) AS 'Total Death Count'
FROM Sarah.coviddeaths
WHERE continent IS NOT NULL AND continent != ''
GROUP BY continent
ORDER BY `Total Death Count` DESC

-- Global Numbers

SELECT SUM(new_cases) AS 'Total Cases',  
SUM(CAST(new_deaths AS SIGNED)) AS 'Total Deaths',
SUM(CAST(new_deaths as SIGNED))/SUM(new_cases)*100 AS 'Death % (Raw Data)',
ROUND(SUM(CAST(new_deaths as SIGNED))/SUM(new_cases)*100,2) AS 'Death %'
FROM Sarah.coviddeaths c
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Total Vaccinations

SELECT
dea.continent AS 'Continent',
dea.location AS 'Location',
dea.date AS 'Date',
dea.population AS 'Population',
vac.new_vaccinations AS 'New Vaccinations',
SUM(CAST(REPLACE(vac.new_vaccinations, ',', '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS 'Rolling People Vaccinated'
FROM
Sarah.coviddeaths dea
JOIN
Sarah.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE
dea.continent IS NOT NULL

-- Use CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS (
SELECT
dea.continent AS 'Continent',
dea.location AS 'Location',
dea.date AS 'Date',
dea.population AS 'Population',
vac.new_vaccinations AS 'New Vaccinations',
SUM(CAST(REPLACE(vac.new_vaccinations, ',', '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS 'Rolling People Vaccinated'
FROM
Sarah.coviddeaths dea
JOIN
Sarah.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE
dea.continent IS NOT NULL)
SELECT *, 
ROUND((Rolling_People_Vaccinated / Population) * 100, 2) AS 'Vaccination %'
FROM PopVsVac

-- Temp Table

DROP TABLE IF EXISTS Sarah.PercentPopulationVaccinated
CREATE TEMPORARY TABLE Sarah.PercentPopulationVaccinated 
(
Continent VARCHAR(255),
Location VARCHAR(255),
Date DATE, 
Population BIGINT, 
New_Vaccinations BIGINT, 
Rolling_People_Vaccinated BIGINT
)

-- Insert data into the temporary table
-- This query calculates the cumulative sum of new_vaccinations
-- and handles potential non-numeric characters in new_vaccinations
-- It also explicitly converts the date string to a DATE type.

INSERT INTO Sarah.PercentPopulationVaccinated
SELECT
dea.continent,
dea.location,
STR_TO_DATE(dea.date, '%m/%d/%Y') AS date, -- Convert date string to DATE type (assuming MM/DD/YYYY format)
dea.population,
CAST(REPLACE(vac.new_vaccinations, ',', '') AS SIGNED) AS new_vaccinations, -- Clean and cast new_vaccinations
SUM(CAST(REPLACE(vac.new_vaccinations, ',', '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY STR_TO_DATE(dea.date, '%m/%d/%Y')) AS Rolling_People_Vaccinated
FROM Sarah.coviddeaths dea
JOIN Sarah.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Query the temporary table to get the final result,
-- including the calculated vaccination percentage

SELECT *,
ROUND((Rolling_People_Vaccinated / Population) * 100, 2) AS 'Vaccination %'
FROM Sarah.PercentPopulationVaccinated

-- Creating View to store Data for later visualizations

CREATE VIEW Sarah.PercentPopulationVaccinated AS
SELECT
dea.continent,
dea.location,
STR_TO_DATE(dea.date, '%m/%d/%Y') AS date, -- Convert date string to DATE type (assuming MM/DD/YYYY format)
dea.population,
CAST(REPLACE(vac.new_vaccinations, ',', '') AS SIGNED) AS new_vaccinations, -- Clean and cast new_vaccinations
SUM(CAST(REPLACE(vac.new_vaccinations, ',', '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY STR_TO_DATE(dea.date, '%m/%d/%Y')) AS Rolling_People_Vaccinated
FROM Sarah.coviddeaths dea
JOIN Sarah.covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM Sarah.percentpopulationvaccinated
