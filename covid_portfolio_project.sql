
-- [DELETE LATER] Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population FROM PortfolioProject..covid_deaths

order by 1,2

-- Looking at Total Cases vs. Total Deaths in all countrys (or in Germany)

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage 
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
-- WHERE location = 'Germany'
ORDER BY 1,2

-- Shows likelihood of dying of you contract covid in Germany

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage 
FROM PortfolioProject..covid_deaths
WHERE location = 'Germany'
ORDER BY 1,2


-- Looking at Total Cases vs. Population#
-- Shows what percentage of population got Covid

SELECT location, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..covid_deaths
-- Get rid of the continents
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, Max((CAST(total_cases AS float) / CAST(population AS float)) * 100) 
AS PercentPopulationInfected
FROM PortfolioProject..covid_deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with highest Death Count per Population

SELECT location, population, MAX(total_deaths) AS HighestDeathCount, MAX(total_cases) AS HighestInfectionCount, Max((CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100) 
AS PercentPopulationDied
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationDied DESC

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--SELECT * FROM PortfolioProject..covid_deaths
--WHERE continent is not NULL
--ORDER BY 1,2

-- Let's break things down by continent
-- Going to be useful later when using Tableau

-- Showing the continents with the highest death count per population 

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS 

SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/ SUM(new_cases) * 100 AS DeathPercentage 
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
-- WHERE location = 'Germany'
-- GROUP BY date (Total)
HAVING SUM(new_cases) != 0
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

SELECT *
FROM PortfolioProject..covid_deaths dea JOIN PortfolioProject..covid_vaccinations vac
ON dea.location = vac.location AND dea.date = vac.date

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) 
  OVER (PARTITION BY dea.location 
  ORDER BY dea.location, dea.date) 
  AS RollingPeopleVaccinated, 
--, (RollingPeopleVaccinated/poulation) * 100 // not possible because RPC is composite expression --> Use CTE or TempTable
FROM PortfolioProject..covid_deaths dea 
JOIN PortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Similar with Group By, but we'll be needing the one above

Select dea.location, SUM(CAST(vac.new_vaccinations AS FLOAT))
FROM PortfolioProject..covid_deaths dea 
JOIN PortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
GROUP BY dea.location

-- USE CTE

WITH PopsVsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) 
  OVER (PARTITION BY dea.location 
  ORDER BY dea.location, dea.date) 
  AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/poulation) * 100 // not possible because RPC is composite expression --> Use CTE or TempTable
FROM PortfolioProject..covid_deaths dea 
JOIN PortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT * , (RollingPeopleVaccinated/population) * 100 FROM PopsvsVac


-- USE TempTable

DROP Table IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated(
	Continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric, 
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) 
  OVER (PARTITION BY dea.location 
  ORDER BY dea.location, dea.date) 
  AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/poulation) * 100 // not possible because RPC is composite expression --> Use CTE or TempTable
FROM PortfolioProject..covid_deaths dea 
JOIN PortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population) * 100 FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS FLOAT)) 
  OVER (PARTITION BY dea.location 
  ORDER BY dea.location, dea.date) 
  AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/poulation) * 100 // not possible because RPC is composite expression --> Use CTE or TempTable
FROM PortfolioProject..covid_deaths dea 
JOIN PortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

DROP VIEW IF exists PercentPopulationVaccinated

SELECT * FROM PercentPopulationVaccinated

