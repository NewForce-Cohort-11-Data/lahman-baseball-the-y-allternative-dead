-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.


-- EDA
SELECT *
FROM homegames
ORDER BY year DESC;

SELECT *
FROM appearances;

SELECT *
FROM homegames;

SELECT *
FROM teams;

SELECT *
FROM teamsfranchises;


-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

--years from teams
SELECT 
	MIN(yearid) AS year_1,
	MAX(yearid) AS year_n
FROM teams;

--years from homegames
SELECT
	MIN(year) AS first_year,
	MAX(year) AS last_year	
FROM homegames;

--years from dates in homegames
SELECT
	EXTRACT(YEAR FROM MIN(span_first)) AS first_year,
	EXTRACT(YEAR FROM MAX(span_last)) AS last_year	
FROM homegames;

--ANSWER: 1871-2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

-- ANSWER: I know this story! :) Let's try Jon Rauch instead!

--trying STRING_AGG, learning how to do this for players that have played for multiple teams, using MAX height = Jon Rauch
--this is cool. returns the team names separated by commas
WITH tallest_player AS (
    SELECT playerid, namefirst, namelast, height
    FROM people
    WHERE height = (SELECT MAX(height) FROM people)
)
SELECT 
    tp.namefirst,
	tp.namelast,
    tp.height,
    SUM(a.g_all) AS total_games,
    STRING_AGG(DISTINCT t.name, ', ') AS teams_played_for
FROM 
    tallest_player tp
JOIN 
    appearances a ON tp.playerID = a.playerID
JOIN 
    teams t ON a.teamID = t.teamID AND a.yearID = t.yearID
GROUP BY 
    tp.nameFirst, tp.nameLast, tp.height;

--Answering initial question with same structure
WITH shortest_player AS (
    SELECT playerid, namefirst, namelast, height
    FROM people
    WHERE height = (SELECT MIN(height) FROM people)
)
SELECT 
    sp.namefirst,
	sp.namelast,
    sp.height,
    SUM(a.g_all) AS total_games,
    STRING_AGG(DISTINCT t.name, ', ') AS teams_played_for
FROM 
    shortest_player sp
JOIN 
    appearances a ON sp.playerID = a.playerID
JOIN 
    teams t ON a.teamID = t.teamID AND a.yearID = t.yearID
GROUP BY 
    sp.nameFirst, sp.nameLast, sp.height;


-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

--finding David Price in salaries table to find out what his total_salary_earned should be
SELECT SUM(salary)::numeric::money
FROM salaries
WHERE playerid = 'priceda01'; --should be $81M, not $245M
--number I was originally getting without subquery
--SELECT 81851296 * 3;

--Finally, with some help!
WITH vandy_players AS (
  SELECT DISTINCT playerid
  FROM collegeplaying
  WHERE schoolid = 'vandy'
),
player_salaries AS (
  SELECT playerid, SUM(salary)::NUMERIC::MONEY AS total_salary_earned
  FROM salaries
  GROUP BY playerid
)
SELECT
  p.namefirst,
  p.namelast,
  ps.total_salary_earned
FROM vandy_players vp
JOIN player_salaries ps ON vp.playerid = ps.playerid
JOIN people p ON p.playerid = vp.playerid
ORDER BY ps.total_salary_earned DESC;

--ANSWER: David Price, "$81,851,296.00"

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT
	SUM(po) AS total_putouts,
	CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		ELSE 'no position?'
	END AS position_type
FROM fielding
WHERE yearid = '2016'
GROUP BY position_type
ORDER BY total_putouts DESC;

--ANSWER: execute query above

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT
	((yearid/10) *10)::TEXT || 's' AS decade,
	--SO = strikeouts by batters -- SOA = strikeouts allowed by pitchers
	ROUND(SUM(so+soa)::NUMERIC / SUM(g), 2) AS avg_Ks_per_game,
	--HR = homeruns by batters -- HRA = homeruns allowed by pitchers
	ROUND(SUM(hr+hra)::NUMERIC / SUM(g), 2) AS avg_HRs_per_game,
	--IF you want it by team, by game use EITHER SO or SOA. They will give you the same number
	ROUND(SUM(so)::NUMERIC / SUM(g), 2) AS avg_Ks_per_game_per_team,
	--IF you want it by team, by game use EITHER HR or HRA. They will give you the same number
	ROUND(SUM(hr)::NUMERIC / SUM(g), 2) AS avg_HRs_per_game_per_team,
	--IF you want it by team, by game use EITHER SO or SOA. They will give you the same number
	ROUND(SUM(soa)::NUMERIC / SUM(g), 2) AS avg_Ks_per_game_per_team,
	--IF you want it by team, by game use EITHER HR or HRA. They will give you the same number
	ROUND(SUM(hra)::NUMERIC / SUM(g), 2) AS avg_HRs_per_game_per_team
	--See how the numbers are exactly half of the avg per game?
	--See how using EITHER HOA or HR give you the same value?
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

--Allyson's so/g:
WITH decades AS 
(SELECT yearid,SUM(so) AS sum_so,SUM(soa) AS sum_soa,SUM(g) AS sum_g,
CASE
	WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
	WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
	WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
	WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
	WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
	WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
	WHEN yearid BETWEEN 1980 AND 1989 THEN '1980s'
	WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
	WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
	WHEN yearid BETWEEN 2010 AND 2016 THEN '2010s'
	ELSE 'pre_1920' END decade
FROM teams
WHERE yearid > 1919
GROUP BY yearid)
SELECT decade,ROUND(SUM(sum_so+sum_soa)/SUM(sum_g)::NUMERIC,2) AS so_per_game
FROM decades
GROUP BY decade
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT namefirst,
	namelast,
	namegiven,
	sb+cs AS stolen_base_attempts,
	sb AS stolen_bases,
	ROUND((SB::NUMERIC/(SB+CS))*100, 2) AS steal_success_rate
FROM batting
JOIN people USING(playerid)
WHERE (SB + CS) >=20
	AND yearid = 2016
ORDER BY steal_success_rate DESC;


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

--maximum reg season wins to not win WS from 1970 to 2016
SELECT yearid,
	name,
	MAX(w) AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
GROUP BY teamID, name, yearid
ORDER BY wins DESC;

--minimum reg season wins to win WS from 1970 to 2016 excluding 1981
SELECT yearid,
	name,
	MIN(w) AS wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
	AND yearid != 1981
GROUP BY teamID, name, yearid
ORDER BY wins;

--did most wins in reg season win WS? RANK then WHERE RANK = 1 and WS = 'Y?'
WITH reg_season_wins AS (
SELECT yearid,
	name,
	w,
	RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS reg_season_win_rank,
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY teamID, name, yearid, w, wswin
)
SELECT *
FROM reg_season_wins
WHERE reg_season_win_rank = 1
	AND wswin = 'Y';



--next step would be counting these 12 rows divided by counting yearid span in CTE? But what about 1994? Have to subtract it?
SELECT ROUND((12::NUMERIC / (2016-1969-1)) *100, 2) AS percent_most_reg_season_wins_won_ws_1970_to_2016_not_including_1994;


--Kyle's percentage
WITH max_per_year AS (
	SELECT
		yearid,
		MAX(w) max_wins
	FROM
		teams
	WHERE 
		yearid BETWEEN 1970 AND 2016
	GROUP BY
		yearid
	ORDER BY
		yearid
)
SELECT 
	ROUND(((COUNT(yearid) / (2016-1970)::numeric)*100), 2) AS max_winner_percentage
FROM
	teams AS t
INNER JOIN
	max_per_year AS m
	USING(yearid)
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND t.w = m.max_wins
	AND wswin = 'Y';



SELECT 2016-1970;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

--high avg attendance
SELECT
	park_name,
	f.franchname AS team_name,
	SUM(h.attendance)/SUM(h.games) AS avg_attendance_per_game
FROM homegames h
JOIN parks p USING(park)
JOIN teams t ON h.team = t.teamid
JOIN teamsfranchises f ON t.franchid = f.franchid
WHERE games >=10
	AND year = 2016
GROUP BY f.franchname, park_name
ORDER BY avg_attendance_per_game DESC
LIMIT 5;

--low avg attendance
SELECT
	park_name,
	f.franchname AS team_name,
	SUM(h.attendance)/SUM(h.games) AS avg_attendance_per_game
FROM homegames h
JOIN parks p USING(park)
JOIN teams t ON h.team = t.teamid
JOIN teamsfranchises f ON t.franchid = f.franchid
WHERE games >=10
	AND year = 2016
GROUP BY f.franchname, park_name
ORDER BY avg_attendance_per_game
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT *
FROM awardsmanagers
ORDER BY yearid, lgid;

-- Can use CTEs, but the output is wonky and it doesn't include some managers because the awardsmanagers table lgid only shows 'ML' for the earlier years because the award wasn't split by league until 1986. Go to bottom to see better query.
WITH AL_TSN_MYA AS (
	SELECT a.playerid,
		p.namefirst || ' ' || p.namelast AS full_name,
		a.lgid,
		m.teamid,
		a.yearid
	FROM awardsmanagers a
	JOIN people p USING(playerID)
	JOIN managers m USING(playerID, yearid)
	WHERE awardid = 'TSN Manager of the Year'
		AND a.lgid = 'AL'
		),
NL_TSN_MYA AS (
	SELECT a.playerid,
		p.namefirst || ' ' || p.namelast AS full_name,
		a.lgid,
		m.teamid,
		a.yearid
	FROM awardsmanagers a
	JOIN people p USING(playerID)
	JOIN managers m USING(playerID, yearid)
	WHERE awardid = 'TSN Manager of the Year'
		AND a.lgid = 'NL'
		)
SELECT al.full_name,
	al.teamid AS al_team,
	al.yearid AS al_year,
	nl.teamid AS nl_team,
	nl.yearid AS nl_year
FROM AL_TSN_MYA al
JOIN NL_TSN_MYA nl ON al.playerid = nl.playerid;

--EDA: Using UNION to look at both tables' data together
SELECT *,
	p.namefirst || ' ' || p.namelast AS full_name,
	a.lgid,
	m.teamid
FROM awardsmanagers a
JOIN people p USING(playerID)
JOIN managers m USING(playerID, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND a.lgid = 'AL'
UNION
SELECT *,
	p.namefirst || ' ' || p.namelast AS full_name,
	a.lgid,
	m.teamid
FROM awardsmanagers a
JOIN people p USING(playerID)
JOIN managers m USING(playerID, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND a.lgid = 'NL';

--looking up my favorite coach, Sparky Anderson
SELECT *
FROM awardsmanagers
WHERE playerid = 'andersp01';

--looking up coaches 
SELECT *
FROM awardsmanagers
WHERE playerid IN ('coxbo01', 'larusto01', 'showabu99', 'leylaji99', 'pinielo01', 'melvibo01', 'johnsda02', 'maddojo99')
ORDER BY playerid;


--This solution returns a table that has lgid from teams table because 'ML' in awardsmanagers lgid
WITH tsn AS (
	SELECT
		a.yearid,
		a.playerid,
		p.namefirst || ' ' || p.namelast AS full_name,
		a.lgid AS award_league,
		t.lgid AS team_league,
		t.teamid,
		t.name,
		a.awardid
	FROM awardsmanagers a
	JOIN people p USING(playerID)
	JOIN managers m USING(playerID, yearid)
	JOIN teams t
		ON m.teamid = t.teamid AND m.yearid = t.yearid
	WHERE awardid = 'TSN Manager of the Year'
	),
both_leagues AS (
	SELECT playerid
	FROM tsn
	GROUP BY playerid
	HAVING COUNT(DISTINCT team_league) >1
	)	
SELECT
	tsn.full_name,
	tsn.team_league,
	tsn.yearid,
	tsn.teamid,
	tsn.name AS team_name,
	tsn.awardid
FROM tsn
JOIN both_leagues bl ON tsn.playerid = bl.playerid
ORDER BY full_name, team_league, yearid;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


SELECT *
FROM batting
JOIN people USING(playerid);

--building the filter for 10+ seasons
SELECT
	playerID,
	COUNT(DISTINCT yearID) AS seasons_played
FROM batting
GROUP BY playerID
HAVING COUNT(DISTINCT yearID) >= 10;

--building the filter for HRs > 0 in 2016
SELECT
	playerID,
	SUM(hr) AS hr
FROM batting
WHERE yearid = 2016
GROUP BY playerid
HAVING SUM(hr)>0;

--building career MAX HR per player
SELECT
	playerID,
	MAX(hr) AS maxhr
FROM batting
GROUP BY playerid
ORDER BY max DESC;

--ADDING THEM (ALL TOGETHER NOW)!
WITH ten_plus_seasons AS (
	SELECT
		playerID,
		COUNT(DISTINCT yearID) AS seasons_played
	FROM batting
	GROUP BY playerID
	HAVING COUNT(DISTINCT yearID) >= 10
	),
HRs_in_2016 AS (
	SELECT
		playerID,
		yearid,
		SUM(hr) AS hr
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid, yearid
	HAVING SUM(hr)>0
	),
career_hr_max AS (
	SELECT
		playerID,
		MAX(hr) AS maxhr
	FROM batting
	GROUP BY playerid
	)
SELECT
	hr.yearid,
	tps.seasons_played,
	crm.maxhr,
	p.namefirst,
	p.namelast,
	hr.hr AS hr_2016
FROM HRs_in_2016 AS hr
JOIN ten_plus_seasons AS tps USING(playerid)
JOIN career_hr_max AS crm USING(playerid)
JOIN people AS p USING(playerid)
WHERE hr.hr = crm.maxhr
ORDER BY hr DESC;


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

--look at player salaries by year (26248 rows)
SELECT
	playerid,
	yearid,
	teamid,
	lgid,
	salary::NUMERIC::MONEY
FROM salaries s
ORDER BY salary DESC;

--look at team salaries by year (918 rows)
SELECT
	teamid,
	yearid,
	SUM(salary)::NUMERIC::MONEY AS salary
FROM salaries s
GROUP BY teamid, yearid
ORDER BY salary DESC;


--join teams and explore data (918 rows). (510 if you s.yearid >= 2000)
WITH team_salaries AS(
	SELECT
		teamid,
		yearid,
		SUM(salary)::NUMERIC::MONEY AS salary
	FROM salaries s
	GROUP BY teamid, yearid
	ORDER BY salary DESC
	),
spending_per_win AS (
	SELECT
		t.name AS team_name,
		t.yearid AS year,
		s.salary,
		t.w AS wins,
		s.salary/t.w AS win_cost,
		*
	FROM team_salaries s
	JOIN teams t USING(teamid, yearid)
	WHERE s.yearid >= 2000)
SELECT *
FROM spending_per_win
ORDER BY win_cost;
--Abandoning this for now. Will revisit later. 



-- 12. In this question, you will explore the connection between number of wins and attendance.
-- -- a.Does there appear to be any correlation between attendance at home games and number of wins?
-- -- b.Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.


--initial thoughts:
--CTE with filter for playoff wins: playoff_teams
WITH playoff_teams AS (
	SELECT
		teamid,
		name,
		yearid,
		attendance,
		wcwin,
		divwin,
		wswin
	FROM teams
	WHERE wcwin = 'Y' OR divwin = 'Y' OR wswin = 'Y'
	)
SELECT
	pt.teamid,
	pt.name,
	pt.yearid AS playoff_year,
	pt.attendance AS playoff_attendance,
	t.yearid AS year_after_playoffs,
	t.attendance AS attendance_after_playoffs,
	(t.attendance - pt.attendance) AS attendance_diff
FROM playoff_teams pt
JOIN teams t
	ON pt.teamid = t.teamid AND pt.yearid +1 = t.yearid --column with next year's attendance (can i use yearid + 1?): YES!
ORDER BY attendance_diff DESC NULLS LAST;
--a few things to account for during future analysis:
--1981 shortened season
--1994 no playoffs
--WWII era attendance
--what if the team changed parks?
--database doesn't have park capacity, so normalizing against that would need additional data
--COVID season if i decide to pull in more recent data?


/*EDA
--3006 rows total in homegames
--2160 rows where homegames tbl attendance != teams tbl attendance
SELECT *
FROM homegames h
JOIN teams t ON h.team = t.teamid AND h.year = t.yearid
ORDER BY h.attendance DESC;

SELECT *
FROM homegames;

SELECT *
FROM teams;
*/

SELECT * 
FROM teams
ORDER BY ghome DESC NULLS LAST;


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

SELECT DISTINCT(throws)
FROM people;

SELECT *
FROM people
WHERE throws = 'S';
--Pat Venditte! Pitcher must declare what hand he will throw with for the entire at bat (barring injury)

--this is 19112 rows for all players
	namefirst || ' ' || namelast AS name,
	--making this more fun
	CASE
		WHEN throws = 'L' THEN 'Lefty'
		WHEN throws = 'R' THEN 'Righty'
		WHEN throws = 'S' THEN 'Switch'
		WHEN throws IS NULL THEN 'No Info'
		ELSE 'something else'
	END AS throwing_hand,
	*
FROM people p
ORDER BY throwing_hand DESC;

--pitchers
SELECT 
	DISTINCT pt.playerid,
	p.namefirst || ' ' || p.namelast AS name,
	p.throws
FROM pitching pt
JOIN people p USING(playerid)
ORDER BY p.throws DESC NULLS LAST;
		
--cy young winners
SELECT 
	namefirst || ' ' || namelast AS name,
	*
FROM awardsplayers
JOIN people USING(playerid)
WHERE awardid = 'Cy Young Award';


SELECT 
	throws,
	*
FROM people;

/*
B
O
N
U
S

Q
U
E
S
T
I
O
N
S
*/

-- In these exercises, you'll explore a couple of other advanced features of PostgreSQL. 

-- 1. In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

-- a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.

-- If you need a hint, you can structure your query as follows:

-- SELECT DISTINCT lgid, ( <Write a correlated subquery here that will pull the teamid for the team with the highest number of wins from each league> )
-- FROM teams t
-- WHERE yearid = 2016;

-- b. One downside to using correlated subqueries is that you can only return exactly one row and one column. This means, for example that if we wanted to pull in not just the teamid but also the number of wins, we couldn't do so using just a single subquery. (Try it and see the error you get). Add another correlated subquery to your query on the previous part so that your result shows not just the teamid but also the number of wins by that team.

-- c. If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.

-- d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword (https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016. 

-- If you want a hint, you can structure your query as follows:

-- SELECT *
-- FROM (SELECT DISTINCT lgid 
-- 	  FROM teams
-- 	  WHERE yearid = 2016) AS leagues,
-- 	  LATERAL ( <Fill in a subquery here to retrieve the teamid and number of wins> ) as top_teams;
	  
-- e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. (Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.


-- 2. Another advantage of lateral joins is for when you create calculated columns. In a regular query, when you create a calculated column, you cannot refer it it when you create other calculated columns. This is particularly useful if you want to reuse a calculated column multiple times. For example,

-- SELECT 
-- 	teamid,
-- 	w,
-- 	l,
-- 	w + l AS total_games,
-- 	w*100.0 / total_games AS winning_pct
-- FROM teams
-- WHERE yearid = 2016
-- ORDER BY winning_pct DESC;

-- results in the error that "total_games" does not exist. However, I can restructure this query using the LATERAL keyword.

-- SELECT
-- 	teamid,
-- 	w,
-- 	l,
-- 	total_games,
-- 	w*100.0 / total_games AS winning_pct
-- FROM teams t,
-- LATERAL (
-- 	SELECT w + l AS total_games
-- ) AS tg
-- WHERE yearid = 2016
-- ORDER BY winning_pct DESC;

-- a. Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called birthdate which is of the date type.

-- b. Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).

-- c. Who is the youngest player to ever play in the major leagues?

-- d. Who is the oldest player to player in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.

-- 3. For this question, you will want to make use of RECURSIVE CTEs (see https://www.postgresql.org/docs/13/queries-with.html). The RECURSIVE keyword allows a CTE to refer to its own output. Recursive CTEs are useful for navigating network datasets such as social networks, logistics networks, or employee hierarchies (who manages who and who manages that person). To see an example of the last item, see this tutorial: https://www.postgresqltutorial.com/postgresql-recursive-query/. 
-- In the next couple of weeks, you'll see how the graph database Neo4j can easily work with such datasets, but for now we'll see how the RECURSIVE keyword can pull it off (in a much less efficient manner) in PostgreSQL. (Hint: You might find it useful to look at this blog post when attempting to answer the following questions: https://data36.com/kevin-bacon-game-recursive-sql/.)

-- a. Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an All Star Game with Willie Mays? (A player started an All Star Game if they appear in the allstarfull table with a non-null startingpos value).

-- b. How many players didn't start in an All Star Game with Willie Mays but started an All Star Game with another player who started an All Star Game with Willie Mays? For example, Graig Nettles never started an All Star Game with Willie Mayes, but he did star the 1975 All Star Game with Blue Vida who started the 1971 All Star Game with Willie Mays.

-- c. We'll call two players connected if they both started in the same All Star Game. Using this, we can find chains of players. For example, one chain from Carlton Fisk to Willie Mays is as follows: Carlton Fisk started in the 1973 All Star Game with Rod Carew who started in the 1972 All Star Game with Willie Mays. Find a chain of All Star starters connecting Babe Ruth to Willie Mays. 

-- d. How large a chain do you need to connect Derek Jeter to Willie Mays?