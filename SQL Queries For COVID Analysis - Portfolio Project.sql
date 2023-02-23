-- Data that is going to be used
SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Total Deaths 
-- Likelihood of dying of covid in any particular country
SELECT Location, Date, Total_Cases, Total_Deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE Location = 'United States' AND Continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Population 
-- How much percentage of population got covid
SELECT Location, Date, Population, Total_Cases, (total_cases/population)*100 as PopulationPercentage
FROM CovidDeaths
WHERE Location = 'United States' AND Continent IS NOT NULL
ORDER BY 1,2


-- Countries with highest infection rate as compared to the total population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPopulationPercentage
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY InfectedPopulationPercentage DESC


-- Countries with highest death rate as compared to the total population
SELECT Location, MAX(CAST(Total_Deaths as INT)) as TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Continents with highest death rate as compared to the total population
SELECT Continent, MAX(CAST(Total_Deaths as INT)) as TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC


-- Correct Values by Continents with highest death rate as compared to the total population
SELECT Location, MAX(CAST(Total_Deaths as INT)) as TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Global Numbers by Date
SELECT CAST(Date as DATE) as Date, SUM(New_Cases) as TotalCases, SUM(CAST(New_Deaths as INT)) as TotalDeaths, (SUM(CAST(New_Deaths as INT))/SUM(New_Cases))*100 as DeathPercentage
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Date
ORDER BY 1,2


-- Over All Global Numbers
SELECT SUM(New_Cases) as TotalCases, SUM(CAST(New_Deaths as INT)) as TotalDeaths, (SUM(CAST(New_Deaths as INT))/SUM(New_Cases))*100 as DeathPercentage
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2


-- Total Population vs Vaccinations
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Total Population vs Vaccinations Rolling Totals
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(CONVERT(BIGINT, vac.New_Vaccinations)) OVER (Partition By dea.Location ORDER BY dea.Location, dea.Date) as RollingTotalValue
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using CTE identifying % of population vaccinated
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(CONVERT(BIGINT, vac.New_Vaccinations)) OVER (Partition By dea.Location ORDER BY dea.Location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingTotalPercentage
FROM PopvsVac
ORDER BY 2,3


-- Using CTE identifying % of population vaccinated - where vaccinations exceed total number of population
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(CONVERT(BIGINT, vac.New_Vaccinations)) OVER (Partition By dea.Location ORDER BY dea.Location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT Location, Population, New_Vaccinations, RollingPeopleVaccinated, (RollingPeopleVaccinated/Population)*100 as RollingTotalPercentage
FROM PopvsVac
GROUP BY Location, Population, New_Vaccinations, RollingPeopleVaccinated
HAVING RollingPeopleVaccinated > Population
ORDER BY 1,4


-- Using Temp Table to identify % of population vaccinated
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(CONVERT(BIGINT, vac.New_Vaccinations)) OVER (Partition By dea.Location ORDER BY dea.Location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingTotalPercentage
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations, 
SUM(CONVERT(BIGINT, vac.New_Vaccinations)) OVER (Partition By dea.Location ORDER BY dea.Location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL