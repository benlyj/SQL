CREATE TABLE covid_deaths(
	iso_code VARCHAR(50),
	continent VARCHAR(50),
	location VARCHAR(100),
	date DATE,
	population NUMERIC(20,3),
	total_cases NUMERIC(20,3),
	new_cases NUMERIC(20,3),
	new_cases_smoothed NUMERIC(20,3),
	total_deaths NUMERIC(20,3),
	new_deaths NUMERIC(20,3),
	new_deaths_smoothed NUMERIC(20,3),
	total_cases_per_million NUMERIC(20,3),
	new_cases_per_million NUMERIC(20,3),
	new_cases_smoothed_per_million NUMERIC(20,3),
	total_deaths_per_million NUMERIC(20,3),
	new_deaths_per_million NUMERIC(20,3),
	new_deaths_smoothed_per_million NUMERIC(20,3),
	reproduction_rate NUMERIC (10,2),
	icu_patients NUMERIC(20,3),
	icu_patients_per_million NUMERIC(20,3),
	hosp_patients NUMERIC(20,3),
	hosp_patients_per_million NUMERIC(20,3),
	weekly_icu_admissions NUMERIC(20,3),
	weekly_icu_admissions_per_million NUMERIC(20,3),
	weekly_hosp_admissions NUMERIC(20,3),
	weekly_hosp_admissions_per_million NUMERIC(20,3)	
);

CREATE TABLE covid_vaccinations(
	iso_code VARCHAR(50),
	continent VARCHAR(50),
	location VARCHAR(100),
	date DATE,
	new_tests NUMERIC(20,3),
	total_tests NUMERIC(20,3),
	total_tests_per_thousand NUMERIC(20,3),
	new_tests_per_thousand NUMERIC(20,3),
	new_tests_smoothed NUMERIC(20,3),
	new_tests_smoothed_per_thousand NUMERIC(20,3),
	positive_rate NUMERIC(20,3),
	tests_per_case NUMERIC(20,3),
	tests_units VARCHAR(100),
	total_vaccinations NUMERIC(20,3),
	people_vaccinated NUMERIC(20,3),
	people_fully_vaccinated NUMERIC(20,3),
	total_boosters NUMERIC(20,3),
	new_vaccinations NUMERIC(20,3),
	new_vaccinations_smoothed NUMERIC(20,3),
	total_vaccinations_per_hundred NUMERIC(20,3),
	people_vaccinated_per_hundred NUMERIC(20,3),
	people_fully_vaccinated_per_hundred NUMERIC(20,3),
	total_boosters_per_hundred NUMERIC(20,3),
	new_vaccinations_smoothed_per_million NUMERIC(20,3),
	stringency_index NUMERIC(20,3),
	population_density NUMERIC(20,3),
	median_age NUMERIC(20,3),
	aged_65_older NUMERIC(20,3),
	aged_70_older NUMERIC(20,3),
	gdp_per_capita NUMERIC(20,3),
	extreme_poverty NUMERIC(20,3),
	cardiovasc_death_rate NUMERIC(20,3),
	diabetes_prevalence NUMERIC(20,3),
	female_smokers NUMERIC(20,3),
	male_smokers NUMERIC(20,3),
	handwashing_facilities NUMERIC(20,3),
	hospital_beds_per_thousand NUMERIC(20,3),
	life_expectancy NUMERIC(20,3),
	human_development_index NUMERIC(20,3),
	excess_mortality_cumulative_absolute NUMERIC(20,3),
	excess_mortality_cumulative NUMERIC(20,3),
	excess_mortality NUMERIC(20,3),
	excess_mortality_cumulative_per_million NUMERIC(20,3)
);

-- check imports
SELECT * FROM covid_deaths;
SELECT * FROM covid_vaccinations;

-- select data to use
SELECT continent, location, date, total_cases, new_cases, total_deaths, population 
FROM covid_deaths
ORDER BY location, date;

-- compare total cases vs total deaths for SG (death rate)
-- shows likelihood of dying if you contract covid
SELECT location, date, total_cases, total_deaths, ROUND(total_deaths/total_cases*100,3) AS death_rate
FROM covid_deaths
WHERE location ILIKE '%singapore%'
ORDER BY location, date;

-- look at total cases vs population (infection rate) in SG
-- shows what percentage of the SG population has contracted covid
SELECT location, date, total_cases, population, ROUND(total_cases/population*100,3) AS infection_rate
FROM covid_deaths
WHERE location ILIKE '%singapore%'
ORDER BY location, date;

-- check countries with highest infection rates (total cases vs population)
-- filter out rows with null in the continent column because these rows will have the location column filled with the continent
-- i.e. select rows where the continent column is not null because this filters out the continent level aggregation
SELECT location, MAX(total_cases) AS highest_infection_count, population, ROUND(MAX(total_cases)/population*100,3) AS max_infection_rate
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING (MAX(total_cases), population, MAX(total_cases)/population) IS NOT NULL
ORDER BY max_infection_rate DESC;

-- check countries with the highest death count
-- filter out rows with null in the continent column because these rows will have the location column filled with the continent
-- i.e. select rows where the continent column is not null because this filters out the continent level aggregation
SELECT location, MAX(total_deaths) AS total_deaths
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY MAX(total_deaths) DESC;

-- check the death count by continent
-- select rows where the continent column is null because these rows have the location column filled with the continent
SELECT location, MAX(total_deaths) AS total_deaths
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY MAX(total_deaths) DESC;

-- check global death rate
SELECT location, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths, ROUND(MAX(total_deaths)/MAX(total_cases)*100,2) AS death_rate
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
HAVING location = 'World';

-- check vaccinations vs population; rolling count of vaccinations
DROP VIEW IF EXISTS vac_vs_pop;

CREATE VIEW vac_vs_pop AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
	FROM covid_deaths AS dea INNER JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY location, date
);

SELECT *, ROUND(rolling_total_vaccinations/population*100,2) AS vac_percent
FROM vac_vs_pop
ORDER BY location, date;
