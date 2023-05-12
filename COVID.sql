SELECT * 
FROM Covid..CovidDeaths as Deaths
ORDER BY Deaths.location, Deaths.date

SELECT * 
FROM Covid..CovidVaccinations as Vacc
ORDER BY Vacc.location, Vacc.date

-- SELECT data we will use
SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM Covid..CovidDeaths
ORDER BY Location, Date

	-- Looking at the total cases VS total deaths
	-- How many cases in the country and what was the % of death per case
	-- Shows the evolution of your chances of dying if you get COVID per country
	SELECT Location, Date, ISNULL(total_cases, 0) AS total_cases_fix, ISNULL(total_deaths, 0) AS total_deaths_fix, (total_deaths/total_cases)*100 AS deathsPerCasesPercentage
	FROM Covid..CovidDeaths
	WHERE location LIKE '%Canada%'
	ORDER BY Location, Date

	-- Total cases vs Population
	-- Measure evolution in time of the spread of the virus in the population per country
	SELECT Location, Date, population, ISNULL(total_cases, 0) AS total_cases_fix, ISNULL(total_deaths, 0) AS total_deaths_fix, (total_cases/population)*100 AS CasesOnPopulationPercentage
	FROM Covid..CovidDeaths
	WHERE location LIKE '%Canada%'
	ORDER BY Location, Date

	-- Countries with highest infection rate compared to population
	SELECT Location, population, MAX(total_cases) AS max_total_cases, MAX(total_cases/population)*100 AS MaxInfectionRate
	FROM Covid..CovidDeaths
	--WHERE location = 'Canada'
	GROUP BY Location, population
	ORDER BY MaxInfectionRate DESC

	-- Countries with highest death
	SELECT Location, MAX(cast(total_deaths as int)) AS totalDeaths
	FROM Covid..CovidDeaths
	--WHERE location = 'Canada'
	WHERE continent IS NOT NULL
	GROUP BY Location
	ORDER BY totalDeaths DESC

	-- Continent with highest death
	SELECT location, MAX(cast(total_deaths as int)) AS totalDeaths
	FROM Covid..CovidDeaths
	--WHERE location = 'Canada'
	WHERE continent IS NULL
	AND location <> 'World'
	GROUP BY location
	ORDER BY totalDeaths DESC

		-- Continent with highest death
	SELECT continent, MAX(cast(total_deaths as int)) AS totalDeaths
	FROM Covid..CovidDeaths
	--WHERE location = 'Canada'
	WHERE continent IS not NULL
	GROUP BY continent
	ORDER BY totalDeaths DESC

	-- GLOBAL NUMBERS
	-- Death rate once infected per day
	SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS deathPercentage
	FROM Covid..CovidDeaths
	WHERE continent is not null
	GROUP BY date
    ORDER BY date, sum(new_cases)

		-- GLOBAL NUMBERS
		-- Death rate once infected total
	SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS deathPercentage
	FROM Covid..CovidDeaths
	WHERE continent is not null
    ORDER BY sum(new_cases)

	-- JOIN THE TWO COVID TABLES
	SELECT *
	FROM Covid..CovidDeaths as dea
	INNER JOIN Covid..CovidVaccinations as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date


	-- USE TEMP TABLE
	-- WHAT IS THE % OF THE WORLD POPULATION THAT HAS BEEN VACCINATED
	DROP TABLE IF EXISTS #PercentPopulationVaccinated
	CREATE TABLE #PercentPopulationVaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	new_vaccinations numeric,
	RollingNewVacc numeric
	)

	INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition By dea.location ORDER BY dea.location, dea.date) AS RollingNewVacc
	FROM Covid..CovidDeaths as dea
	INNER JOIN Covid..CovidVaccinations as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
	WHERE dea.continent is not null
	
	--New vaccinations % on the total population based on the temp table
	SELECT *, (RollingNewVacc/Population)*100 as NewVacPercentageBasedOnPopulation
	FROM #PercentPopulationVaccinated
	ORDER BY 2,3

	-- CREATING VIEW TO STORE DATA FOR FUTURE VISUALS

	-- Evolution of total covid deaths in the world
	CREATE VIEW TotalWorldDeathsEvo as
	SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS deathPercentage
	FROM Covid..CovidDeaths
	WHERE continent is not null
	GROUP BY date

	-- CREATE MORE VIEWS WITH JOIN ETC...