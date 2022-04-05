Use PortofolioProject;

SET SQL_SAFE_UPDATES = 0;
SET sql_mode=(SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', '')); -- this is in order to use aggregate functions without the group by clause
SELECT * 
FROM coviddeaths;

SELECT * 
FROM covidvaccinations;

/* DROP TEMPORARY TABLE temp_Afganistan;

CREATE TEMPORARY TABLE temp_Afganistan(
iso_code VARCHAR(100),
continent VARCHAR(100),
location VARCHAR(100),
date TEXT
);

INSERT INTO temp_Afganistan
SELECT iso_code, continent, location, date
FROM coviddeaths
WHERE iso_code = 'AFG';

UPDATE temp_Afganistan
SET temp_Afganistan.date = STR_TO_DATE(temp_Afganistan.date, '%Y-%m-%d %T');

SELECT temp_Afganistan.date
FROM temp_Afganistan; */


-- Select data that we will be using


-- Looking at Total cases vs Total deaths

-- Shows a rough estimate of dying if you contract COVID in your country


SELECT Location,date,total_cases,new_cases,total_deaths,population
FROM coviddeaths
ORDER BY 1,2;



SELECT Location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM coviddeaths
WHERE location like'%states%'
ORDER BY 1,2;



-- Looking at Total_cases vs Population
-- Shows what percentage of the population got COVID
SELECT Location,date,population,total_cases, (total_cases/population)*100 as Case_Percentage
FROM coviddeaths
-- WHERE location like'%states%'
WHERE continent NOT LIKE ''
ORDER BY 1,2;



-- Looking at countries with highest infection rate compraed to population 


SELECT Location,population,MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM coviddeaths
-- WHERE location like'%states%'
WHERE continent NOT LIKE ''
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC;


-- Showing countries with the highest death count per population


SELECT Location, max(cast(total_deaths as signed)) /* the cast(total_deaths as int) wasnt working */ as TotalDeathCount
FROM  coviddeaths
-- WHERE location like'%states%'
WHERE continent NOT LIKE ''  /* i am using the NOT LIKE clause and not the IS NOT NULL since the data was imported with a blank space string insted of a null value*/
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Cleaning up the data because some entries show with a location 'Asia' whereas others with a continent field 'Asia'

SELECT *
FROM coviddeaths
WHERE continent NOT LIKE ''
ORDER BY 3,4;


-- Let's break thing down by continent

SELECT continent, max(cast(total_deaths as signed)) /* the cast(total_deaths as int) wasnt working */ as TotalDeathCount
FROM  coviddeaths
WHERE continent NOT LIKE ''  /* i am using the NOT LIKE clause and not the IS NOT NULL since the data was imported with a blank space string insted of a null value*/
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- this is the correct way to check data per continent
SELECT Location, max(cast(total_deaths as signed)) /* the cast(total_deaths as int) wasnt working */ as TotalDeathCount
FROM  coviddeaths
-- WHERE location like'%states%'
WHERE continent LIKE ''  /* i am using the NOT LIKE clause and not the IS NOT NULL since the data was imported with a blank space string insted of a null value*/
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Showing the continents with the highest death count


SELECT continent, max(cast(total_deaths as signed)) /* the cast(total_deaths as int) wasnt working */ as TotalDeathCount
FROM  coviddeaths
-- WHERE location like'%states%'
WHERE continent NOT LIKE ''  /* i am using the NOT LIKE clause and not the IS NOT NULL since the data was imported with a blank space string insted of a null value*/
GROUP BY continent
ORDER BY TotalDeathCount DESC;



-- Global numbers


SELECT date,SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(new_cases)*100 as DeathPercentage -- total_cases,total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM coviddeaths
-- WHERE location like'%states%'
WHERE continent NOT LIKE '' 
-- Group By date 
ORDER BY 1,2;


-- Looking at total population vs vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as signed)) OVER (Partition BY dea.location ORDER BY dea.location,dea.date) AS TotalRunningVaccinations -- /,(TotalRunningCountVaccinations/dea.population)*100 AS PercentageTotalVaccination
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent NOT LIKE ''
ORDER BY 2,3;


SELECT *
FROM covidvaccinations
WHERE location = 'Netherlands';

-- USE CTE

WITH PopVsVac(continent, location,date,population,new_vaccinations,new_vaccinations_smoothed,TotalRunningCountVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,vac.new_vaccinations_smoothed,
SUM(cast(vac.new_vaccinations_smoothed as signed)) OVER (Partition BY dea.location ORDER BY dea.location,dea.date) AS TotalRunningCountVaccinations /*,(TotalRunningCountVaccinations/dea.population)*100 as PercentageTotalVaccination */
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent NOT LIKE ''
-- ORDER BY 2,3
)
SELECT *, (TotalRunningCountVaccinations/population)*100 as Percentage
FROM PopVsVac;


-- USING Temp table
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
new_vaccinations_smoothed numeric,
TotalRunningCountVaccinations numeric
);

INSERT INTO PercentPopulationVaccinated -- there is an error 1292 about a integer value ''
SELECT vac.continent, vac.location, vac.date, dea.population,cast(vac.new_vaccinations as signed INT),cast(vac.new_vaccinations_smoothed as signed INT),
SUM(cast(vac.new_vaccinations_smoothed as signed)) OVER (Partition BY dea.location ORDER BY dea.location,dea.date) AS TotalRunningCountVaccinations /*,(TotalRunningCountVaccinations/dea.population)*100 as PercentageTotalVaccination */
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
    AND dea.date = vac.date;
-- WHERE dea.continent NOT LIKE '';

SELECT *, (TotalRunningCountVaccinations/population)*100 as Percentage
FROM PopVsVac;

-- Using Views in order to store data for later visualisations

CREATE VIEW TotalRunningCountVaccinations as
SELECT vac.continent, vac.location, vac.date, dea.population,cast(vac.new_vaccinations as signed INT),cast(vac.new_vaccinations_smoothed as signed INT),
SUM(cast(vac.new_vaccinations_smoothed as signed)) OVER (Partition BY dea.location ORDER BY dea.location,dea.date) AS TotalRunningCountVaccinations /*,(TotalRunningCountVaccinations/dea.population)*100 as PercentageTotalVaccination */
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent NOT LIKE '';
-- ORDER BY 2,3;

Select *
FROM TotalRunningCountVaccinations;


/*
UPDATE coviddeaths
SET coviddeaths.date = STR_TO_DATE(coviddeaths.date,'%Y-%m-%d %T'); 

UPDATE covidvaccinations
SET covidvaccinations.date = STR_TO_DATE(covidvaccinations.date,'%Y-%m-%d %T'); */
INSERT INTO PercentPopulationVaccinated SELECT dea.continent, dea.location, dea.date, dea.population,cast(vac.new_vaccinations as unsigned),cast(vac.new_vaccinations_smoothed as unsigned), SUM(cast(vac.new_vaccinations_smoothed as signed)) OVER (Partition BY dea.location ORDER BY dea.location,dea.date) AS TotalRunningCountVaccinations /*,(TotalRunningCountVaccinations/dea.population)*100 as PercentageTotalVaccination */ FROM coviddeaths dea JOIN covidvaccinations vac ON dea.location = vac.location     AND dea.date = vac.date WHERE dea.continent NOT LIKE ''
