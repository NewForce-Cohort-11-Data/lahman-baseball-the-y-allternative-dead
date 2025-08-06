-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.


-- EDA
SELECT *
FROM homegames
ORDER BY year DESC;


-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

SELECT 
	MIN(yearid) AS year_1,
	MAX(yearid) AS year_n
FROM teams;

--ANSWER: 1871-2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT *
FROM people
JOIN appearances USING(playerid)
WHERE playerid = 'gaedeed01';

-- ANSWER: I know this story! :) Need to add query above though.

--trying something, learning how to do this for other players that have played for multiple teams MAX height = Jon Rauch
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
    SUM(b.G) AS total_games,
    STRING_AGG(DISTINCT t.name, ', ') AS teams_played_for
FROM 
    tallest_player tp
JOIN 
    Batting b ON tp.playerID = b.playerID
JOIN 
    Teams t ON b.teamID = t.teamID AND b.yearID = t.yearID
GROUP BY 
    tp.nameFirst, tp.nameLast, tp.height;






-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

--finding David Price in salaries table to find out what his total_salary_earned should be
SELECT SUM(salary)::numeric::money
FROM salaries
WHERE playerid = 'priceda01';

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
	TO_CHAR(SUM(po), 'FM999,999,999') AS total_putouts,
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



--trying to get each team by year. but if I change games to an odd number like 161 I'm still getting the same number. Do I have to average instead of dividing by game? this is totally wrong. start over tomorrow 8/7
SELECT *
	,yearid
	,teamid
	--so = strikeouts by batters
	,ROUND((so/g), 2) AS batter_Ks_per_game
	--soa = strikouts by pitchers
	,ROUND((soa/g), 2) AS pitcher_Ks_per_game
	--HR = homeruns by batters
	,ROUND((hr/g), 2) AS batter_HRs_per_game
	--HRA = homeruns allowed by pitchers
	,ROUND((hra/g), 2) AS HR_allowed_by_pitchers
	--shouldn't I have to divide all this by 2 since this is doubling everything for each team that played the game? Or only calculate either batters or pitchers, and not all four categories.
FROM teams
ORDER BY batter_Ks_per_game DESC NULLS LAST;

--trying average, changing to 161 instead of 162 games. still doesn't solve the problem
SELECT
	yearid
	,teamid
	--so = strikeouts by batters
	,ROUND(AVG(so/161), 2) AS batter_Ks_per_game
	--soa = strikouts by pitchers
	,ROUND(AVG(soa/161), 2) AS pitcher_Ks_per_game
	--HR = homeruns by batters
	,ROUND(AVG(hr/161), 2) AS batter_HRs_per_game
	--HRA = homeruns allowed by pitchers
	,ROUND(AVG(hra/161), 2) AS HR_allowed_by_pitchers
	--shouldn't I have to divide all this by 2 since this is doubling everything for each team that played the game? Or only calculate either batters or pitchers, and not all four categories.
FROM teams
GROUP BY yearid, teamid
ORDER BY batter_Ks_per_game DESC NULLS LAST;


SELECT 1543/159;


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

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