---Covid-19 Data Exploration
---Skills used:Aggregate Functions, Joins, CTE's, Temp Table, Converting data types, Windows Function, Creating views

SELECT *
FROM CovidDeaths
where continent is not null
Order by 3,4

--SELECT *
--FROM CovidVaccinations
--Order by 3,4

---Select data that I will be starting with
SELECT Location,date,total_cases,new_cases, total_deaths, population
FROM CovidDeaths
Order by Location, date

---Shows the probability of dying if you contract Covid in Kenya

SELECT 
	Location,
	date,
	total_cases,
	total_deaths, (
	total_deaths/total_cases)*100 As DeathPercentage
FROM CovidDeaths
WHERE Location like '%Kenya%'
Order by Location, date

---Total Cases vs Total Deaths
---Shows what percentage of population is infected with Covid

SELECT 
	Location,
	date,
	population, 
	total_cases, (total_cases/population)*100 As PercentageOfPopulationInfected
FROM CovidDeaths
WHERE Location like '%Kenya%'
Order by Location, date

---Showing countries with highest infection rate compared to population

SELECT 
	Location,
	population, 
	MAX(total_cases) AS HighestInfectionCount,
	MAX(total_cases/population)*100 As PercentagePopulationInfected

FROM CovidDeaths
--WHERE Location like '%Kenya%'
Group by location, population
Order by PercentagePopulationInfected desc

---Showing countries with the higest death count per population

SELECT 
	Location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount

FROM CovidDeaths
WHERE continent is not null
Group by location
Order by TotalDeathCount desc

---Breaking things down by Continent
---Showing continents with the highest death count per population

SELECT 
	continent,
	MAX(cast(total_deaths as int)) AS TotalDeathCount

FROM CovidDeaths
WHERE continent is NOT null
Group by continent
Order by TotalDeathCount desc

---GLOBAL NUMBERS

SELECT  
	sum(new_cases) as totalCases,
	sum(cast(new_deaths as int)) as totalDeaths,
	sum(cast(new_deaths as int))/sum(cast(new_cases as int))*100 As PercentageOfPopulationInfected

FROM CovidDeaths
---WHERE Location like '%Kenya%'
Where continent is not null
---Group by Date
Order by 1,2

--Total population vs vaccinations
--Shows Percentage of population that has received at least one Covid vaccine
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinationated
	---(RollingPeopleVaccinationated)/population)*100
FROM CovidDeaths dea   
Join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
Group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
order by 2,3

---Using CTE to perform calculation on Partition by in previous query

With PopvsVac (continent,location,date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinationated
	---(RollingPeopleVaccinationated)/population)*100
FROM CovidDeaths dea   
Join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
Group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--order by 2,3
)
select* , (RollingPeopleVaccinated/population)*100
from PopvsVac

---Using temp table to perform calculations on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

---creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 