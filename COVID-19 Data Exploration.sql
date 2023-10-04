--Data that will be analyzed

select * from death
select * from vax

--Ordering countries by mortality rate for each day expressed in terms of percent and category

select location, max(total_deaths)/max(total_cases)*100 as mortality_rate,
case 
  when max(total_deaths)/max(total_cases)*100 > 5 then 'severe'
  when max(total_deaths)/max(total_cases)*100 <= 5 and max(total_deaths)/max(total_cases)*100 >= 3 then 'moderate'
  else 'low'
end as Category
from death where total_cases != 0 and total_deaths != 0 group by location order by mortality_rate

--Ordering countries by mortality rate represented as percent and quartile per country

select location, max(total_deaths)/max(total_cases)*100 as mortality_rate, 
NTILE(4) over (order by max(total_deaths)/max(total_cases)*100)
from death where total_cases IS NOT NULL and total_cases != 0 and continent is not NULL 
and total_deaths != 0 group by location, population order by 2

--Ordering countries by infection rate and death rate

select location, max(total_cases) as total_infection_count, 
max(total_cases/population)*100 as total_infection_percent
from death where continent is not NULL group by location
order by total_infection_percent desc

select location, max(cast(total_deaths as int)) as total_death_count, 
max(cast(total_deaths as int)/population)*100 as total_death_percentage
from death group by location, population
order by total_death_count desc

--Global Continent Figures- infection rate, death rate and mortality rate in a temp table and view

create table #global_deaths 
(continent nvarchar(255), population float, total_deaths int, total_cases float, mortality_rate float, 
total_infection_rate float, total_death_percent float)

insert into #global_deaths select location, population, 
max(cast(total_deaths as int)), sum(new_cases), max(cast(total_deaths as int))/max(total_cases)*100,
max(cast(total_cases as int))/population*100, max(cast(total_deaths as int))/population*100
from death where continent is NULL and location != 'World' and location != 'International' and location != 'European Union'
group by location, population

Create View global_deaths as 
select location, population, 
max(cast(total_deaths as int)) as total_deaths, sum(new_cases) as total_cases, max(cast(total_deaths as int))/max(total_cases)*100 as mortality_rate,
max(cast(total_cases as int))/population*100 as total_infection_rate, max(cast(total_deaths as int))/population*100 
as total_death_percent from death where continent is NULL and location != 'World' and location != 'International' and location != 'European Union'
group by location, population

select * from #global_deaths order by mortality_rate desc

--Vaccination Data- finding the vaccination percent for at least one dose,
--both doses and testing percent

select * from death join vax on death.location = vax.location
and death.date = vax.date order by death.location

With vax_global (location, population, vaccination_count, fully_vaccinated_count, total_test_count) 
as 
(
Select 
	death.location, 
	death.population, 
	max(cast(vax.people_vaccinated as int)) as vaccination_count,
	MAX(cast(vax.people_fully_vaccinated as int)) as fully_vaccinated_count,
	MAX(cast(vax.total_tests as int)) as total_test_count
from 
	death join vax on death.location = vax.location
	and 
	death.date = vax.date
where 
	death.continent is not NULL group by death.location, death.population
) 
select *, (vaccination_count/population)*100 as vaccination_percent, (fully_vaccinated_count/population)*100 as full_vaccination_percent,
(total_test_count/population)*100 as test_percent
from vax_global order by location

--Storing the above CTE queries in a view

create view vax_global as
Select death.location, death.population, max(cast(vax.people_vaccinated as int)) as vaccination_count,
max(cast(vax.people_fully_vaccinated as int)) as fully_vaccinated_count,
max(cast(vax.total_tests as int)) as total_test_count,
(max(cast(vax.people_vaccinated as int))/population)*100 as vaccination_percent, 
(max(cast(vax.people_fully_vaccinated as int))/population)*100 as full_vaccination_percent,
(max(cast(vax.total_tests as int))/population)*100 as test_percent
from death join vax on death.location = vax.location and death.date = vax.date
where death.continent is not NULL group by death.location, death.population

select * from vax_global





