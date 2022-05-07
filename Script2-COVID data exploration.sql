---- COVID data exploration "How indonesia really handled the pandemic"

--Query to answer 5 specific questions
--1. What is the mortality rate and infection rate of covid in indonesia? 
--2. How does Indonesia rank in global case mortality rate?
--3. Is there a correlation between government policies and infection rate?
--4. How does indonesia rank against other countries with similar population size and density?
--5. How did all the metrics grow between march of 2020 to march of 2022

--definitions:
--mortality rate(MR): (Amount of deaths divided by population)x100
--case fatality rate(CFR): (Amount of deaths divided by amount of cases)x100. Also known as deathrate
--infection rate(IR): (amount of cases divided by population)x100

--Question 1:
--Infection rate, and mortality rate in the world
--Ranking is least to most
select 
	continent,
	location, 
	population, 
	population_density,
	MAX(total_cases) as total_Cases, 
	MAX(total_deaths) as total_deaths,
	(Max(total_cases)/Population)*100 as InfectionRate, 
	RANK() over (order by Max(total_cases)/Population*100) IRRank,
	(Max(total_deaths)/Population)*100 as MortalityRate,
	RANK() over (order by Max(total_deaths)/Population*100) MRRank
from owid_covid_data_csv ocdc
where total_deaths is not null
	and population is not null
	and location not like '%income%'
	and continent <> ''
group by continent, location, population, population_density 
order by infectionrate
--INSIGHTS: 
---Indonesia is ranked 62 out of 209 globally in lowest infection rates (ranked from lowest to highest) with only 2.2% of the population infected
---indonesia is ranked 93 out of 209 globally in lowest mortality rate (ranked from lowest to highest)
---This means that although Indonesia's case fatality rate (risk of dying when infected) is relatively high. 
---That number is affected by Indonesia's low infection count relative to population size.
---Indonesia is also ranked 18 in most total cases, while being ranked 4th in population size and ranked 63 in population density

--Question 2:
--The average CFR of countries/continents in the world
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
	ROUND(cast((total_deaths/total_cases)*100 as numeric), 2) as CaseFatalityRate
from total
order by casefatalityrate desc
--INSIGHTS:
---Indonesia is ranked 25th globally in CFR at 2.6% (2.6% of infected people die)
---Indonesia is ranked 9th in total deaths at 156.240 deaths
---This is a relatively high case fatality rate for the 6 million total cases in Indonesia
---Research shows that CFR is affected minimally by healthcare. And is most affected by population density, testing numbers, and airport traffic, followed by higher age groups


--Questions 3:
--Is there a correlation between government policy dates, and covid metrics?
--LEGEND:
--for the column stay_at_home_requirement
-- 0 = No measures
-- 1 = Recommended not to leave the house
-- 2 = Required to not leave the house with exceptions for daily exercise, grocery shopping, and ‘essential’ trips
with ppi_date as (
select 
	split_part(date, '-', 1) as year,
	split_part(date, '-', 2) as month, 
	date,
	"Day",
	population,
	total_cases,
	new_cases,
	total_deaths,
	new_deaths,
	ROUND(((total_cases/population)*100)::numeric, 6) as InfectionRate,
	stay_home_requirements
from owid_covid_data_csv ocdc 
	left outer join portfolioproject.public."Stay_at_home_policies" sahp 
		on "date" = "Day"
where location = 'Indonesia'
	and entity = 'Indonesia'
order by "date" 
)
select 
	year, 
	month, 
	Max(population) population, 
	max(total_cases) totalcases, 
	sum(new_cases) newcases,
	sum(new_deaths) newdeaths,
	max(infectionrate) infectionrate,
	max(ppi_date.stay_home_requirements) stay_at_home_requirements
from ppi_date
group by year, month
order by year, month

--METHOD:
--This analysis is done by combining the overall world covid data with, world stay-at-home-requirements data from ourworldindata.com

--INSIGHTS:
--There is little to no correlation between stay at home requirements and infection rate growth in Indonesia
--The data shows that infection rates peak when stay at home requirements are at its highest
--The first peak is in january 2021, this is after 9 months of high level social limitation
--The second peak is in July 2021, after 5 months of high level social limitation after the first peak
--The third peak happened in february 2022, after 3 months of high level social limitation followed by 3 months of medium level limitation

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
	(totaldeaths/totalcases)*100 as casefatalityrate 
from totals
order by casefatalityrate DESC

--indonesia metrics against countries with similar population size
with totals as (
select 
	continent,
	location, 
	population, 
	population_density,
	avg(new_cases) as average_new_cases,
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
	average_new_cases,
	totaldeaths, 
	totalcases, 
	(totaldeaths/totalcases)*100 as cfr
from totals
order by 4 DESC

--Covid metrics of countries in asia
with totals as (
select 
	continent,
	location, 
	population, 
	population_density, 
	avg(new_cases) as average_new_cases,
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
	average_new_cases,
	totaldeaths, 
	totalcases, 
	(totaldeaths/totalcases)*100 as death_rate 
from totals
order by 4 desc

--SPECIAL: CFR of countries with similar total cases
with maxes as (
select 
	location, 
	population, 
	population_density, 
	avg(new_cases) as average_new_cases,
	max(total_cases) totalcases, 
	max(total_deaths) totaldeaths
from owid_covid_data_csv ocdc 
where total_deaths is not null
		and continent <> ''
group by location, population, population_density
)
select
	"location",
	population,
	population_density,
	average_new_cases,
	Totalcases,
	totaldeaths,
	totaldeaths/totalcases*100 as CFR
from maxes
where totalcases between 5000000 and 7000000
order by 4 DESC

--INSIGHTS:
--Indonesia has the highest case fatality rate in countries with similar population density (+-25)
--Indonesia has the highest case fatality rate in countries with similar population size (+-100.000.000)
--Indonesia has the 5th highest case fatality rate in asia
--And Indonesia has the 2nd highest case fatality rate in countries with similar total cases (+-1.000.000)
--This shows that Indonesia's CFR is very high in most contexts

--Question 5
--How did all the metrics grow between march of 2020 to march of 2022
select 
	location, 
	date, 
	population, 
	population_density, new_cases, 
	total_cases, total_deaths, 
	avg(new_cases) over () average_new_cases,
	(total_deaths/total_cases)*100 as death_rate
from owid_covid_data_csv ocdc 
where location in ('Indonesia')
		and total_deaths is not null
order by date 

--INSIGHTS:
--There are 3 peaks of infection. January 2021, July 2021, and february 2022.
--The day with the highest CFR is 2 april 2020 at 9.5% and it goes down cosistently untill it gets to around 2.5%-3.3%
--The average daily new cases is 7.751 which is very high ni most contexts (2nd in countries with similar total cases, 7th in asia, 3rd in countries with similar population size)
--for reference the united states had 102.813 average daily new cases

--END
