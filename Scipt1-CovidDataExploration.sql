-- COVID data exploration "How indonesia really handled the pandemic"
---- COVID data exploration "How indonesia really handled the pandemic"

--Query Clean Up to answer 5 specific questions
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

--GLOBAL: Percentage of the population that got infected. Indonesia = 2,18%, United States = 24,4% 
select 
	location, 
	population, 
	MAX(total_cases) as total_Cases, 
	(Max(total_cases)/Population)*100 as PercentInfectedPopulation
from owid_covid_data_csv ocdc
where total_cases is not null
		and population is not null
group by location, population
order by PercentInfectedPopulation desc

--GLOBAL: Percentage of the population that died (indonesia is ranked 96 out of 217 in least percent of population that died)
select 
	location, 
	population, 
	MAX(total_deaths) as total_deaths, 
	(Max(total_deaths)/Population)*100 as PercentPopulationDied
from owid_covid_data_csv ocdc
where total_deaths is not null
	and population is not null
	and location not like '%income%'
group by location, population
order by 4

--NATIVE: Indonesia general covid situation
select 
	location, 
	date, 
	population, 
	population_density, new_cases, 
	total_cases, total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	max((total_deaths/total_cases)*100) over (partition by "location") as max_dr
from owid_covid_data_csv ocdc 
where location in ('Indonesia')
		and total_deaths is not null
order by date


--SPECIAL: countries that has a comparable population to indonesia 
select 
	distinct location, 
	ROUND(population_density) as POP_DEN, 
	ROUND(population) as POP
from owid_covid_data_csv ocdc 
where population BETWEEN 176361792 and 376361792

--SPECIAL: countries that has comparable population density to indonesia
select 
	distinct location, 
	ROUND(population_density) as POP_DEN, 
	ROUND(population) as POP
from owid_covid_data_csv ocdc 
where population_density between 96 and 196




--SPECIAL: average death rate in countries with similar population +- 100.000.000 (total deaths/total cases)*100
select 
	location, 
	date, 
	population, 
	population_density, 
	new_cases, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	avg((total_deaths/total_cases)*100) over (partition by "location") as avg_dr
from owid_covid_data_csv ocdc 
where population between 176361792 and 376361792
		and total_deaths is not null
order by location, date

--SPECIAL: total deaths in countries with similar population +- 100.000.000

select 
	location, 
	population, 
	population_density, 
	MAX(total_deaths) as total_deaths,
	avg((total_deaths/total_cases)*100) as avg_dr
from owid_covid_data_csv ocdc 
where population between 176361792 and 376361792
		and total_deaths is not null
group by location, population, population_density 
order by location

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

--SPECIAL: total deaths and average death rate in countries with similar pop des

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
	and population_density between 121 and 171
group by location, population, population_density
order by avg_dr DESC


--SPECIAL: Highest death rate in countries with similar population +- 100.000.000
with dr_table as (
select 
	location, 
	date, 
	population, 
	population_density, 
	new_cases, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	max((total_deaths/total_cases)*100) over (partition by "location") as max_dr
from owid_covid_data_csv ocdc 
where location in ('Indonesia', 'United States', 'Pakistan', 'Brazil', 'Nigeria')
		and total_deaths is not null
order by date
)
select 
	location, 
	date, 
	population, 
	total_cases, 
	death_rate
from dr_table
where death_rate = max_dr

--SPECIAL: severity of deathrate in countries with similar population +- 100.000.000 (death rate with total cases between 1.000 and 10.000)
with dr_table as (
select 
	location, 
	date, 
	population, 
	population_density, 
	new_cases, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	max((total_deaths/total_cases)*100) over (partition by "location") as max_dr
from owid_covid_data_csv ocdc 
where location in ('Indonesia', 'United States', 'Pakistan', 'Brazil', 'Nigeria')
	and total_deaths is not null
	and total_cases BETWEEN 1000 and 10000
order by date
)
select 
	"location", 
	total_cases, 
	date, max(death_rate) over (partition by "location") as max_dr
from dr_table
where death_rate = max_dr
order by max_dr desc

--SPECIAL: severity of deathrate in countries with similar population +- 100.000.000 (death rate with total cases between 10.000 and 100.000)
with dr_table as (
select 
	location, 
	date, 
	population, 
	population_density, 
	new_cases, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	max((total_deaths/total_cases)*100) over (partition by "location") as max_dr
from owid_covid_data_csv ocdc 
where location in ('Indonesia', 'United States', 'Pakistan', 'Brazil', 'Nigeria')
		and total_deaths is not null
		and total_cases BETWEEN 10000 and 100000
order by date
)
select 
	"location", 
	total_cases, 
	date, 
	max(death_rate) over (partition by "location") as max_dr
from dr_table
where death_rate = max_dr
order by max_dr desc

--SPECIAL: severity of deathrate in countries with similar population +- 100.000.000 (death rate with total cases between 100.000 and 1.000.000)
with dr_table as (
select 
	location, 
	date, 
	population, 
	population_density, 
	new_cases, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	max((total_deaths/total_cases)*100) over (partition by "location") as max_dr
from owid_covid_data_csv ocdc 
where location in ('Indonesia', 'United States', 'Pakistan', 'Brazil', 'Nigeria')
		and total_deaths is not null
		and total_cases between 100000 and 1000000
order by date
)
select "location", total_cases, date, max(death_rate) over (partition by "location") as max_dr
from dr_table
where death_rate = max_dr
order by max_dr desc


--SPECIAL: severity of deathrate in countries with similar population +- 100.000.000 
--(death rate with total cases between 1.000.000 and 100.000.000)
with dr_table as (
select 
	location, 
	date, 
	population, 
	population_density, 
	new_cases, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_rate, 
	max((total_deaths/total_cases)*100) over (partition by "location") as max_dr
from owid_covid_data_csv ocdc 
where location in ('Indonesia', 'United States', 'Pakistan', 'Brazil', 'Nigeria')
		and total_deaths is not null
		and total_cases between 1000000 and 100000000
order by date
)
select "location", total_cases, date, max(death_rate) over (partition by "location") as max_dr
from dr_table
where death_rate = max_dr
order by max_dr desc

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

--How vaccination affected infection, amount of people vaccinated VS new cases
--conclusion : no noticeable correlation
with vacratetable as (
select 
	split_part(vacdata.date, '-', 1) as year,
	split_part(vacdata.date, '-', 2) as month, 
	vacdata.population, 
	vacdata.people_vaccinated_c,
	ocdc.total_cases,
	new_cases,
	lead(new_cases) over (order by ocdc.date),
	(new_cases/ocdc.total_cases)*100 as infectionrate,
	(new_cases/ocdc.population)*100 as popinfectionrate,
	(vacdata.people_vaccinated_c/vacdata.population)*100 as VacRate
from vacdata
	join owid_covid_data_csv ocdc 
		on ocdc.location = vacdata.location
		and ocdc.date = vacdata.date
where people_vaccinated_c is not null
	and new_cases <> 0
order by vacdata.date
)
select 
	year, 
	month, 
	max(total_cases) as sum_cases,
	sum(new_cases) as sum_new_cases,
	round(max(vacrate)::numeric, 2) as percentpeoplevaccinated,
	round(sum(infectionrate)::numeric, 2) as infectionrateP,
	sum(round(sum(infectionrate)::numeric, 2)) over () as totalinfp
from vacratetable
group by year, month
order by 1,2


select*
from vacdata
