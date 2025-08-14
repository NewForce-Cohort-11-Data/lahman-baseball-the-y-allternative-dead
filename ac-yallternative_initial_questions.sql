-- Initial Questions

-- 1. What range of years for baseball games played does the provided database cover?
	-- 1871-2016, 143 years

SELECT DISTINCT year
FROM homegames
ORDER BY year;

SELECT MAX(year), MIN(year)
FROM homegames;

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
	--"Eddie"	"Gaedel"	43	 1	"SLA" : played in 1 game (per Mike, 1 at bat, 4 balls)

SELECT playerid,namefirst,namelast,height,debut,finalgame
FROM people
ORDER BY height ASC
LIMIT 1;

SELECT playerid,teamid
FROM appearances
WHERE playerid = 'gaedeed01';

SELECT *
FROM homegames
WHERE team = 'SLA' AND year = 1951;

SELECT *
FROM collegeplaying
WHERE playerid = 'gaedeed01';

SELECT namefirst,namelast,height,g_all,team
FROM people
LEFT JOIN appearances
USING (playerid)
LEFT JOIN homegames
ON teamid = team
ORDER BY height ASC
LIMIT 1;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total 
-- salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in 
-- the majors?
	-- 24 Vanderbilt alum played for the majors. Highest earner: "David"	"Price"	"$81,851,296.00"
	
-- checking school name format
SELECT *
FROM schools
WHERE schoolname ILIKE '%vander%';

-- result = triple the double check, so not correct
SELECT DISTINCT playerid,namefirst,namelast,SUM(salary) AS total_salary
FROM people
LEFT JOIN collegeplaying
USING (playerid)
LEFT JOIN schools
USING (schoolid)
LEFT JOIN salaries
USING (playerid)
WHERE schoolname ILIKE '%vanderbilt%'
GROUP BY playerid,namefirst,namelast
ORDER BY total_salary DESC; 

-- subqueries...??? no return (gave up and moved to try CTE)
SELECT DISTINCT playerid,namefirst,namelast,SUM(salary) AS total_salary
FROM salaries
LEFT JOIN people
USING (playerid)
LEFT JOIN collegeplaying
USING (playerid)
-- LEFT JOIN schools
-- USING (schoolid)
WHERE schoolid IN
(SELECT schoolname 
FROM schools
WHERE schoolname ILIKE '%vanderbilt%')
GROUP BY playerid,namefirst,namelast
ORDER BY total_salary DESC; 

-- CTE worked!!!! matches double check
WITH vander_players AS (
SELECT DISTINCT playerid,namefirst,namelast,salary
FROM people
LEFT JOIN collegeplaying
USING (playerid)
LEFT JOIN schools
USING (schoolid)
LEFT JOIN salaries
USING (playerid)
WHERE schoolname ILIKE '%vanderbilt%')
SELECT namefirst,namelast,COALESCE(SUM(salary),0)::numeric::money AS total_salary
FROM vander_players
GROUP BY namefirst,namelast
ORDER BY total_salary DESC;

-- double check that answer is correct
SELECT DISTINCT playerid,SUM(salary)
FROM salaries
WHERE playerid = 'priceda01'
GROUP BY playerid;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position 
-- "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three 
-- groups in 2016.
	-- "Battery"	41424
	-- "Infield"	58934
	-- "Outfield"	29560

SELECT CASE
	WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = 'SS' THEN 'Infield'
	WHEN pos = '1B' THEN 'Infield'
	WHEN pos = '2B' THEN 'Infield'
	WHEN pos = '3B' THEN 'Infield'
	WHEN pos = 'P' THEN 'Battery'
	WHEN pos = 'C' THEN 'Battery'
	END AS field_pos,
	SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY field_pos;

-- checking yearid format
SELECT yearid
FROM fielding;

-- checking pos fields
SELECT DISTINCT pos
FROM fielding;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per 
-- game. Do you see any trends?
	-- avg strikeouts per game: "1920s"	5.63, "1930s"	6.63, "1940s"	7.10, "1950s"	8.80, "1960s"	11.43, "1970s"	10.29, "1980s"	10.73, "1990s"	12.30, 
			-- "2000s"	13.12, "2010s"	15.04
	-- avg homeruns per game: "1920s"	0.80, "1930s"	1.09, "1940s"	1.05, "1950s"	1.69, "1960s"	1.64, "1970s"	1.49, "1980s"	1.62, "1990s"	1.91,
			-- "2000s"	2.15, "2010s"	1.97

-- strike out options: so = strike outs by batter, soa = strike outs by pitcher
SELECT so,soa
FROM teams
WHERE teamid = 'FW1' and yearid = '1871';

-- homegames table isn't sufficient (doesn't match #'s in teams table)
SELECT team,year,games
FROM homegames
WHERE team = 'FW1' and year = '1871';

SELECT teamid,yearid,g,ghome
FROM teams
WHERE teamid = 'FW1' and yearid = '1871';

-- avg stikeouts per year, NOT per game - rounded
SELECT yearid,teamid,g,ROUND(AVG(so),2)
FROM teams
GROUP BY yearid,teamid,g
ORDER BY yearid;

-- I need: avg of all strikeouts (so + soa) per game = (so+soa)/g, and rounded ONLY FOR 1 TEAM -- math is correct when checked!
SELECT so,soa,g
FROM teams
WHERE teamid = 'FW1' and yearid = '1871';

SELECT ROUND(SUM((so+soa)/g::NUMERIC),2) AS so_per_game
FROM teams
WHERE teamid = 'FW1' and yearid = '1871';

-- separating decades
SELECT yearid,SUM(so) AS sum_so,SUM(soa) AS sum_soa,SUM(g) AS sum_g,
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
GROUP BY yearid
ORDER BY yearid;

-- strikeouts per game by decade since 1920
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
SELECT decade,ROUND(SUM(sum_so+sum_soa)/SUM(sum_g)::NUMERIC,2) AS avg_so_per_game
FROM decades
GROUP BY decade
ORDER BY decade;

--double check strikeouts for math
SELECT yearid,SUM(so) AS sum_so,SUM(soa) AS sum_soa,SUM(g) AS sum_g
FROM teams
WHERE yearid > 1919 AND yearid < 1930
GROUP BY yearid
ORDER BY yearid;

-- homerun's per game per decade since 1920
WITH decades AS 
(SELECT yearid,SUM(hr) AS sum_hr,SUM(hra) AS sum_hra,SUM(g) AS sum_g,
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
SELECT decade,ROUND(SUM(sum_hr+sum_hra)/SUM(sum_g)::NUMERIC,2) AS avg_hrs_per_game
FROM decades
GROUP BY decade
ORDER BY decade;

--double check for math
SELECT yearid,SUM(hr) AS sum_hr,SUM(hra) AS sum_hra,SUM(g) AS sum_g
FROM teams
WHERE yearid > 1919 AND yearid < 1930
GROUP BY yearid
ORDER BY yearid;

--Mike's query:
SELECT
	((yearid/10) *10)::TEXT || 's' AS decade,
	--SO = strikeouts by batters
	ROUND(SUM(so+soa)::NUMERIC / SUM(g), 2) AS avg_Ks_per_game,
	--HR = homeruns by batters
	ROUND(SUM(hr+hra)::NUMERIC / SUM(g), 2) AS avg_HRs_per_game
FROM teams
WHERE yearid >= 1920
GROUP BY (yearid/10)*10
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are 
-- successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen 
-- bases.
	-- 47 players returned, top player: "Chris"	"Owings"	91.30

-- sb info per player in 2016
SELECT playerid,sb,cs
FROM batting
WHERE yearid = 2016
ORDER BY sb DESC;

-- total_sb_attempts per player in 2016
SELECT playerid,sb,
SUM(sb+cs) AS total_sb_attempts
FROM batting
WHERE yearid = 2016 --AND playerid = 'altuvjo01' (used to doucle check)
GROUP BY playerid,sb
ORDER BY total_sb_attempts DESC;

-- % sb_attempts that are successful, formula: sb / SUM(sb+sc) 
WITH sb_attempts AS
(SELECT playerid,sb,
SUM(sb+cs) AS total_sb_attempts
FROM batting
WHERE yearid = 2016
GROUP BY playerid,sb)
SELECT namefirst,namelast,ROUND((SUM(sb::NUMERIC/total_sb_attempts)*100),2) AS percent_sb_attempts
FROM sb_attempts
LEFT JOIN people
USING (playerid)
WHERE total_sb_attempts > 19
GROUP BY namefirst,namelast
ORDER BY percent_sb_attempts DESC;

--Mike's query:
SELECT namefirst,
	namelast,
	namegiven,
	birthcountry,
	sb+cs AS stolen_base_attempts,
	sb AS stolen_bases,
	ROUND((SB::NUMERIC/(SB+CS))*100, 2) AS steal_success_rate
FROM batting
JOIN people USING(playerid)
WHERE (SB + CS) >=20
	AND yearid = 2016
ORDER BY steal_success_rate DESC;


-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team 
-- that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is 
-- the case. 

		-- largest # wins, no world series: "SEA"	116	2001
		SELECT teamid,w,yearid
		FROM teams
		WHERE wswin = 'N' AND yearid > 1969 AND yearid < 2017
		ORDER BY w DESC;

		-- smallest # wins, yes world series: "LAN"	63	1981 (less games in 1981 due to strike)
		SELECT teamid,w,yearid
		FROM teams
		WHERE wswin = 'Y' AND yearid > 1969 AND yearid < 2017
		ORDER BY w ASC;

	-- Then redo your query, excluding the problem year.

		-- smallest # wins, yes world series, no 1981(year with smallest # wins by ws winner): "SLN"	83	2006
		SELECT teamid,w,yearid
		FROM teams
		WHERE wswin = 'Y' AND yearid > 1969 AND yearid < 2017 AND yearid != 1981
		ORDER BY w ASC;

-- 7 continued. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

		-- team most wins per year
			WITH ranked_teams AS (
    			SELECT yearid,teamid,w,
        			RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS win_rank
   			 	FROM teams
    			WHERE yearid BETWEEN 1970 AND 2016	)
			SELECT yearid, teamid, w
			FROM ranked_teams
			WHERE win_rank = 1
			ORDER BY yearid;
			
		-- team most wins per year - years with ties only: 1971,2002,2003,2006,2007,2013
			-- **got this query with help from ChatGPT using my first query as a starting point because it was an after thought and I didn't want to 
			-- think anymore or bother anyone else**
			WITH ranked_teams AS (
   				SELECT yearid, teamid, w,
           			RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS win_rank
    			FROM teams
    			WHERE yearid BETWEEN 1970 AND 2016	)
			SELECT yearid, teamid, w
			FROM (
    			SELECT yearid, teamid, w,
           		COUNT(*) OVER (PARTITION BY yearid ORDER BY w DESC
                          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS num_top_teams
    		FROM ranked_teams
    		WHERE win_rank = 1	) sub
			WHERE num_top_teams > 1
			ORDER BY yearid, teamid;
			
		-- list of teams that won world series 1970-2016
			SELECT teamid,wswin,yearid
			FROM teams
			WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016
			ORDER BY yearid;

		-- left join and CTE? *Can't get clean result - eg: 1971, OAK and BAL show as wining ws
			WITH ws_winners AS (
				SELECT teamid,wswin,yearid
				FROM teams	
				WHERE wswin = 'Y'		),
			ranked_teams AS (
    			SELECT yearid,teamid,w,
        			RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS win_rank
   			 	FROM teams
    			WHERE yearid BETWEEN 1970 AND 2016	)
			SELECT DISTINCT(ranked_teams.teamid),ranked_teams.w,ws_winners.wswin,ranked_teams.yearid
			FROM ranked_teams, ws_winners
			WHERE win_rank = 1
			ORDER BY yearid;	
			
		-- trying again incl. CASE WHEN *closer but shows all teams
			WITH ranked_teams AS (
    			SELECT yearid,teamid,w,
        			RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS win_rank
   			 	FROM teams
    			WHERE yearid BETWEEN 1970 AND 2016	),
				ws_winners AS (
				SELECT yearid,teamid AS ws_winner
				FROM teams	
				WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016	)
			SELECT ranked_teams.teamid,ranked_teams.w,ws_winners.ws_winner,ranked_teams.yearid,
				CASE WHEN ranked_teams.teamid = ws_winners.ws_winner THEN 'Y' ELSE 'N' END AS mostw_wonws
			FROM ranked_teams
			LEFT JOIN ws_winners
			USING (yearid)
			WHERE win_rank = 1
			ORDER BY yearid;
			
		-- trying again move CASE WHEN to WHERE subquery? YES!!!!!! 12 teams, in years: 1970,1975,1976,1978,1984,1986,1989,1998,2007,2009,2013,2016 
					--(per ties query above 2007 and 2013 ws winners had ties for most wins)
			WITH ranked_teams AS (
    			SELECT yearid,teamid,w,
        			RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS win_rank
   			 	FROM teams
    			WHERE yearid BETWEEN 1970 AND 2016	),
			ws_winners AS (
				SELECT yearid,teamid AS ws_winner
				FROM teams	
				WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016	)
			SELECT ranked_teams.teamid,ranked_teams.w,ws_winners.ws_winner,ranked_teams.yearid
			FROM ranked_teams
			LEFT JOIN ws_winners
			USING (yearid)
			WHERE win_rank = 1 AND ranked_teams.teamid = ws_winners.ws_winner
			ORDER BY yearid;
			
-- 7 continued. What percentage of the time? (did teams with highest winning games win the ws)
	-- according to query (list of teams that won world series 1970-2016) above, there were 46 ws from 1970-2016 (no ws was played in 1994), 12 teams had the highest 
	-- number of winning games (or tied) from 1970-2016. 
	-- 12 / 46 = 26.09%

		--Mike's query:
WITH reg_season_wins AS (
SELECT yearid,
	franchname,
	w,
	RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS reg_season_win_rank,
	wswin
FROM teams
JOIN teamsfranchises USING(franchid)
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY teamID, franchname, yearid, w, wswin
)
SELECT *
FROM reg_season_wins
WHERE reg_season_win_rank = 1
	AND wswin = 'Y';

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average 
-- attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park 
-- name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT *
FROM homegames
WHERE year = '2016'	

	-- highest avg attend by teams and parks, 2016, avg = (total attendance / # of games), @ least 10 games
		-- 31 rows returned, highest attendance: 3703312	81	"LAN"	"LOS03"
SELECT attendance,games,team,park
FROM homegames
WHERE year = '2016'	
ORDER BY attendance DESC;  
	
	-- making sure I don't need to sum attendace
		-- 31 rows returned, highest attendance: 3703312	81	"LAN"	"LOS03"
SELECT park,SUM(attendance) AS total_attend
FROM homegames
WHERE year = '2016'
GROUP BY park
ORDER BY total_attend DESC; 	

	-- top 5 average attendance per game in 2016: 
		-- park		team	avg_attendace
		-- "LOS03"	"LAN"	45719.90
		-- "STL10"	"SLN"	42524.57
		-- "TOR02"	"TOR"	41877.77
		-- "SFO03"	"SFN"	41546.37
		-- "CHI11"	"CHN"	39906.42
SELECT park,team,ROUND(SUM(attendance::NUMERIC / games),2) AS avg_attend
FROM homegames
WHERE year = '2016' AND games > 10
GROUP BY team,park,games,attendance
ORDER BY avg_attend DESC
LIMIT 5;
		
	-- lowest 5 average attendance per game in 2016
		-- park		team	avg_attendace
		-- "STP01"	"TBA"	15878.56
		-- "OAK01"	"OAK"	18784.02
		-- "CLE08"	"CLE"	19650.21
		-- "MIA02"	"MIA"	21405.21
		-- "CHI12"	"CHA"	21559.17
SELECT park,team,ROUND(SUM(attendance::NUMERIC / games),2) AS avg_attend
FROM homegames
WHERE year = '2016' AND games > 10
GROUP BY team,park,games,attendance
ORDER BY avg_attend ASC
LIMIT 5;

--Mike's query:
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

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the 
-- teams that they were managing when they won the award. 
		-- 2 coaches: 
		--"Davey"	"Johnson"	1997	"AL"	"BAL"
		--"Davey"	"Johnson"	2012	"NL"	"WAS"
		--"Jim"		"Leyland"	1988	"NL"	"PIT"
		--"Jim"		"Leyland"	1990	"NL"	"PIT"
		--"Jim"		"Leyland"	1992	"NL"	"PIT"
		--"Jim"		"Leyland"	2006	"AL"	"DET"

SELECT *
FROM awardsmanagers;

	-- managers who won for both leagues: 2 returned - "johnsda02", "leylaji99"
SELECT playerid
FROM awardsmanagers
WHERE awardid ILIKE '%TSN Manager of the Year%'
AND lgid IN ('NL', 'AL')
GROUP BY playerid
HAVING COUNT(DISTINCT lgid) > 1;

	-- adding full names and teams
SELECT p.namefirst, p.namelast, am.yearid, am.lgid, m.teamid
FROM awardsmanagers AS am
	LEFT JOIN managers AS m
	ON am.playerid = m.playerid AND am.yearid = m.yearid
		LEFT JOIN people AS p
		ON am.playerid = p.playerid
WHERE am.awardid ILIKE '%TSN Manager of the Year%'
	AND am.lgid IN ('NL', 'AL')
	AND am.playerid IN (
		SELECT playerid
		FROM awardsmanagers
		WHERE awardid ILIKE '%TSN Manager of the Year%'
		AND lgid IN ('NL', 'AL')
		GROUP BY playerid
		HAVING COUNT(DISTINCT lgid) > 1		)
ORDER BY p.namelast;		

	-- double check
SELECT playerid, awardid, yearid, lgid
FROM awardsmanagers
WHERE awardid ILIKE '%TSN Manager of the Year%'
AND playerid = 'johnsda02'; --2 years: 1997(AL), 2012(NL)

SELECT playerid, awardid, yearid, lgid
FROM awardsmanagers
WHERE awardid ILIKE '%TSN Manager of the Year%'
AND playerid = 'leylaji99'; --4 years: 1988(NL), 1990(NL), 1992(NL), 2006(AL)

-- Mike's query:
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


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, 
-- and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
	-- 9 rows returned. Lowest (tied): 2016	11	"Francisco"	"Liriano"	1	1   and   2016	19	"Bartolo"	"Colon"	1	1
	-- Highest: 2016	12	"Edwin"	"Encarnacion"	42	42

	-- MAX for each player
WITH max_career_hr AS (
	SELECT playerID,MAX(hr) AS max_hr
	FROM batting
	GROUP BY playerid	)

	-- players 10+ years
WITH decade_players AS (
	SELECT playerid, COUNT(DISTINCT yearid) AS yrs_played
	FROM batting
	GROUP BY playerid
	HAVING COUNT(DISTINCT yearid) >= 10		)

	-- hr per player in 2016
WITH total_hr_2016 AS (
	SELECT playerid,SUM(hr) AS sum_hr_2016
	FROM batting
	WHERE yearid = 2016 AND hr > 0
	GROUP BY playerid	)

	-- combine + name
WITH decade_players AS (
	SELECT playerid,COUNT(DISTINCT yearid) AS yrs_played
	FROM batting
	GROUP BY playerid
	HAVING COUNT(DISTINCT yearid) >= 10		),
total_hr_2016 AS (
	SELECT playerid,yearid,SUM(hr) AS sum_hr_2016
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid,yearid
	HAVING SUM(hr) > 0	),
max_career_hr AS (
	SELECT playerID,MAX(hr) AS max_hr
	FROM batting
	GROUP BY playerid	)
SELECT thr.yearid,dp.yrs_played,p.namefirst,p.namelast,mch.max_hr,thr.sum_hr_2016
FROM total_hr_2016 AS thr
	INNER JOIN decade_players AS dp USING (playerid)
	INNER JOIN max_career_hr AS mch USING (playerid)
	INNER JOIN people AS p USING (playerid)
WHERE thr.sum_hr_2016 = mch.max_hr
ORDER BY sum_hr_2016 ASC;


--Mike's query:

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





