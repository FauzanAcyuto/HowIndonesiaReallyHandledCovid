-- COVID data exploration "How indonesia really handled the pandemic"

--Query to answer 5 specific questions
--1. What percentage of the population died and what percentage got infected? 
--2. What is the average death rate?
--3. Is there a correlation between government policies and COVID metrics
--4. How does indonesia rank against other countries with similar population size and density?
--5. How did all the metrics grow between march of 2020 to march of 2022



--Question 1:
--Percent of population that got infected, and percent of population that died in the world
select 
	continent,
	location, 
	population, 
	population_density,
	MAX(total_cases) as total_Cases, 
	MAX(total_deaths) as total_deaths,
	(Max(total_cases)/Population)*100 as InfectedPopulation, 
	(Max(total_deaths)/Population)*100 as PopulationDied
from owid_covid_data_csv ocdc
where total_deaths is not null
	and population is not null
	and location not like '%income%'
group by continent, location, population, population_density 
order by total_deaths DESC


--Question 2:
--The average deathrate of countries/continents in the world
with Total as (
select 
	continent,
	location, 
	population, 
	population_density,
	MAX(total_cases) as total_cases,
	MAX(total_deaths) as total_deaths
from owid_covid_data_csv ocdc 
where total_deaths is not null
	and continent <> ''
group by continent, location, population, population_density
)
select 
	continent,
	location,
	population,
	population_density,
	total_cases,
	total_deaths,
	population_density,
	ROUND(cast((total_deaths/total_cases)*100 as numeric), 2) as DeathRate
from total
order by Deathrate DESC


--Questions 3:
--Is there a correlation between government policy dates, and covid metrics?
with ppi_date as (
select 
	split_part(date, '-', 1) as year,
	split_part(date, '-', 2) as month, 
	population,
	total_cases,
	ROUND(((total_cases/population)*100)::numeric, 6) as PercentInfected
from owid_covid_data_csv ocdc 
where location = 'Indonesia'
order by "date" 
)
select 
	year, 
	month, 
	Max(population) population, 
	max(total_cases) maxtotalcases, 
	sum(percentinfected) percentinfected
from ppi_date
group by year, month
order by year, month


--Question 4:
--How does indonesia rank against other countries with similar population size and density?

--Indonesia metrics against countries with similar pop_des
with totals as (
select 
	continent,
	location, 
	population, 
	population_density, 
	MAX(total_deaths) as totaldeaths,
	MAX(total_cases) as totalcases
from owid_covid_data_csv ocdc 
where 
	total_deaths is not null
	and continent <> ''
	and population_density between 121 and 171
group by continent, location, population, population_density
)
select
	continent,
	location,
	rank() over (order by totaldeaths/totalcases DESC) as DRrank,
	population,
	population_density,
	totaldeaths,
	totalcases,
	(totaldeaths/totalcases)*100 as death_rate 
from totals

--indonesia metrics against countries with similar population size
with totals as (
select 
	continent,
	location, 
	population, 
	population_density, 
	MAX(total_deaths) as totaldeaths,
	max(total_cases) as totalcases
from owid_covid_data_csv ocdc
where 
	total_deaths is not null
	and continent <> ''
	and population between 176361792 and 376361792
group by continent, location, population, population_density
)
select 
	continent, 
	location, 
	population, 
	totaldeaths, 
	totalcases, 
	(totaldeaths/totalcases)*100 as death_rate 
from totals
order by death_rate DESC

--Covid metrics of countries in asia
with totals as (
select 
	continent,
	location, 
	population, 
	population_density, 
	MAX(total_deaths) as totaldeaths,
	MAX(total_cases) as totalcases
from owid_covid_data_csv ocdc 
where 
	total_deaths is not null
	and continent = 'Asia'
group by continent, location, population, population_density
)
select 
	continent, 
	location, 
	population, 
	totaldeaths, 
	totalcases, 
	(totaldeaths/totalcases)*100 as death_rate 
from totals
order by death_rate desc

--Question 5
--How did all the metrics grow between march of 2020 to march of 2022
select 
	location, 
	date, 
	population, 
	population_density, new_cases, 
	total_cases, total_deaths, 
	(total_deaths/total_cases)*100 as death_rate
from owid_covid_data_csv ocdc 
where location in ('Indonesia')
		and total_deaths is not null
order by date 

--END


---all queries
--full data
select *
from owid_covid_data_csv ocdc 

--cleaning data
----clean vaccination data temp table
drop table if exists Vacdata;
create temp table VacData as (
select 
	location, 
	date, 
	population, 
	total_cases,  
	NULLIF(people_vaccinated,'')::float as people_vaccinated_C,
	NULLIF(new_vaccinations,'')::float as new_vaccinations_C,
	NULLIF(total_vaccinations,'')::float as total_vaccination_C,
	NULLIF(people_fully_vaccinated,'')::float as people_fully_vaccinated_C
from owid_covid_data_csv ocdc 
where location in ('Indonesia')
order by people_vaccinated desc
);
select *
from Vacdata;


--GLOBAL: Global COVID data
select *
from owid_covid_data_csv ocdc 
where location = 'World'
order by total_cases

--GLOBAL: continental numbers
select 
	continent,
	max(total_cases) as totalcases, 
	max(total_deaths) as totaldeaths,  
	avg(total_deaths/total_cases)*100 as avg_dr,
	Max(total_cases/Population)*100 as PercentInfectedPopulation,
	max(date) as date
from owid_covid_data_csv ocdc 
where continent is not null
group by continent
order by totalcases desc

--GLOBAL: total deaths and average death rate in the world

select 
	location, 
	population, 
	population_density, 
	MAX(total_deaths) as total_deaths,
	avg(total_deaths/total_cases)*100 as avg_dr
from owid_covid_data_csv ocdc 
where 
	total_deaths is not null
	and continent <> ''
group by location, population, population_density
order by avg_dr desc



--NATIVE: vaccination rate development in indonesia
with vacratetable as (
select 
	split_part(date, '-', 1) as year,
	split_part(date, '-', 2) as month, 
	population, 
	people_vaccinated_c, 
	(people_vaccinated_c/population)*100 as VacRate
from vacdata
where people_vaccinated_c is not null
order by date
)
select 
	year, 
	month, 
	round(max(vacrate)::numeric, 2) as percentpeoplevaccinated
from vacratetable
group by year, month
order by 1,2

--NATIVE: infected population precentage by month
with ppi_date as (
select 
	split_part(date, '-', 1) as year,
	split_part(date, '-', 2) as month, 
	population,
	total_cases,
	ROUND(((total_cases/population)*100)::numeric, 6) as PercentPopInfected
from owid_covid_data_csv ocdc 
where location = 'Indonesia'
order by "date" 
)
select 
	year, 
	month, 
	Max(population) population, 
	max(total_cases) maxtotalcases, 
	sum(percentpopinfected) percentpopinfected
from ppi_date
group by year, month
order by year, month


