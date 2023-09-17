DROP TABLE IF EXISTS athlete_events;
CREATE TABLE IF NOT EXISTS athlete_events
(
    id          INT,
    name        VARCHAR,
    sex         VARCHAR,
    age         VARCHAR,
    height      VARCHAR,
    weight      VARCHAR,
    team        VARCHAR,
    noc         VARCHAR,
    games       VARCHAR,
    year        INT,
    season      VARCHAR,
    city        VARCHAR,
    sport       VARCHAR,
    event       VARCHAR,
    medal       VARCHAR
);

DROP TABLE IF EXISTS noc_regions;
CREATE TABLE IF NOT EXISTS noc_regions
(
    noc         VARCHAR,
    region      VARCHAR,
    notes       VARCHAR
);

SELECT COUNT(*) FROM athlete_events;
SELECT COUNT(*) FROM noc_regions;

--Number of olympic games have taken place
SELECT COUNT(DISTINCT games) as total_games
FROM athlete_events;

--List down the year, season, and city of the games held so far
SELECT DISTINCT year, season, city
FROM athlete_events
ORDER BY year;

--The total number of nations that took part in each olympic game
WITH total_num_countries AS
			(SELECT DISTINCT games, nr.region 
			 FROM athlete_events as ae
			 JOIN noc_regions as nr
			 ON ae.noc = nr.noc
			 GROUP BY games, nr.region)
SELECT games, COUNT(games) as total_countires
FROM total_num_countries
GROUP BY games
ORDER BY games;

--indicate the highest and lowest num of countries participatin in olypmics
WITH all_countries AS								
				(SELECT games, nr.region
				 FROM athlete_events as ae
				 JOIN noc_regions as nr
				 ON ae.noc = nr.noc
				 GROUP BY games, nr.region),
total_countries AS								
		(SELECT games, COUNT(games)as total_countries
		 FROM all_countries
		 GROUP BY games)
SELECT DISTINCT									--use concatination and over clause
		CONCAT(first_value(games) OVER(ORDER BY total_countries), ' - '
      , first_value(total_countries) OVER(ORDER BY total_countries)) as Lowest_Countries,

		CONCAT(first_value(games) OVER(ORDER BY total_countries DESC), ' - '
      , first_value(total_countries) OVER(ORDER BY total_countries DESC)) as Highest_Countries

      FROM total_countries
      ORDER BY Lowest_Countries;


-- nationa that have been part of every olympic games
WITH total_games AS										--first cte to find the num of distinct games
      (SELECT COUNT(DISTINCT games) as total_num_games
	   FROM athlete_events),
countries AS											--second cte to join tables to find country
		(SELECT  games, nr.region as country 
		 FROM athlete_events as ae
		 JOIN noc_regions as nr
		 ON ae.noc = nr.noc
		 GROUP BY games, nr.region),
countries_participated as								--third cte to find total countries participated based on second cte
		(SELECT country, COUNT(country) as total_participated_games
		 FROM countries
		 GROUP BY country)
SELECT cp.*												-- join first and third cte
FROM countries_participated as cp
JOIN total_games as tg 
ON cp.total_participated_games = tg.total_num_games
ORDER BY 1;


--Sport that was played all summer olympics
WITH total_num as   				--first cte to find total num of summer games
			(SELECT COUNT(DISTINCT games) as total_summer_games
			FROM athlete_events 
			WHERE season ='Summer'),
sport_play as						--second cte to find how many games where each sport palyed in
			(SELECT DISTINCT sport, COUNT(DISTINCT games) as total_games
			FROM athlete_events
			GROUP BY sport)
SELECT *
FROM sport_play as sp
JOIN total_num as tn
ON sp.total_games = tn.total_summer_games;


--sport that was only played once in all olympics
WITH sport_played as
				(SELECT DISTINCT sport , COUNT(DISTINCT games)as num_games
				FROM athlete_events
				GROUP BY sport
				HAVING COUNT(DISTINCT games) = 1),
game_year as
				(SELECT DISTINCT games, sport 
				FROM athlete_events)
SELECT sp.* , gy.games
FROM sport_played as sp
JOIN game_year as gy 
ON sp.sport = gy.sport
ORDER BY gy.sport

--overall count of sports played in each olympic games
SELECT games , COUNT(DISTINCT sport) as num_of_sports
FROM athlete_events
GROUP BY games
ORDER BY num_of_sports DESC, games 

--oldest athletes who win a gold medal
SELECT DISTINCT name, MAX(age) as age, medal
FROM athlete_events
WHERE medal= 'Gold' AND age <> 'NA'
GROUP BY name, medal
ORDER BY age DESC, name DESC;

--assign order to the num of male and female athletes participated in all games 
SELECT ROW_NUMBER() OVER(ORDER BY sex) as order_num, sex, COUNT(sex) as count_sex
FROM athlete_events
GROUP BY sex

- top athletes who have won the most gold medals
SELECT name, team, COUNT(medal) as total_num
FROM athlete_events
where medal = 'Gold'
GROUP BY name, team
ORDER BY count(medal)DESC;

--Top 5 athlete who have won the most medals (bronze/silver/gold)
WITH m_medal as
		   (SELECT name, team, COUNT(medal) as total_medal
			FROM athlete_events
			WHERE medal IN ('Gold','silver','bronze')
			GROUP BY name, team),
top_five as
		(SELECT *, dense_rank() OVER(ORDER BY total_medal DESC) as rnk
		 FROM m_medal)
SELECT name, team, total_medal
FROM top_five
WHERE rnk <= 5
LIMIT 5;

--top 5 countries that won the most num of medals
WITH most_medals as
		(SELECT nr.region, COUNT(nr.region) as total_medals
		FROM noc_regions nr
		JOIN athlete_events ae
		ON ae.noc = nr.noc
		WHERE medal <> 'NA'
		GROUP BY nr.region), 
five_countries as
				(SELECT *, DENSE_RANK() OVER(ORDER BY total_medals DESC) as rnk
				FROM most_medals)
SELECT *
FROM five_countries
WHERE rnk <= 5;

--list down all types of medals by countries
CREATE EXTENSION IF NOT EXISTS tablefunc;				--First create tablefunc

SELECT country, coalesce(gold, 0)as gold,
 				 coalesce(silver, 0) as silver,
    			 coalesce(bronze, 0) as bronze
FROM CROSSTAB('SELECT nr.region as country
    			, medal
    			, count(1) as total_medals
    			FROM  athlete_events as ae
    			JOIN noc_regions nr ON nr.noc = ae.noc
    			where medal <> ''NA''
    			GROUP BY nr.region,medal
    			order BY nr.region,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
AS FINAL_RESULT(country varchar, bronze bigint, gold bigint, silver bigint)
ORDER BY gold DESC, silver DESC, bronze DESC;