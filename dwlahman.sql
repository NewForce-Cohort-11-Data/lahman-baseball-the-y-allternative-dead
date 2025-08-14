-- What range of years for baseball games played does the provided database cover?
SELECT
	MIN(debut) AS earliest_date,
	MAX(finalgame) AS latest_date
FROM people;


-- Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT    people.namefirst,
          people.namelast,
          people.height,
          SUM(appearances.g_all) AS total_games_played,
          teams.name AS team_name
FROM      people
JOIN      appearances ON people.playerid = appearances.playerid
JOIN      teams ON appearances.teamid = teams.teamid
AND       appearances.yearid = teams.yearid
AND       appearances.lgid = teams.lgid
WHERE     people.height = (
          SELECT    MIN(height)
          FROM      people
          WHERE     height IS NOT NULL
          )
GROUP BY  people.namefirst,
          people.namelast,
          people.height,
          teams.name;

  
-- Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?   David Price
SELECT   p.nameFirst,
         p.nameLast,
         SUM(s.salary) AS total_salary
FROM     CollegePlaying cp
JOIN     Schools sc ON cp.schoolID = sc.schoolID
JOIN     People p ON cp.playerID = p.playerID
JOIN     Salaries s ON cp.playerID = s.playerID
WHERE    sc.schoolName = 'Vanderbilt University'
GROUP BY p.nameFirst, p.nameLast
ORDER BY total_salary DESC;


SELECT
  p.nameFirst,
  p.nameLast,
  TO_CHAR (SUM(s.salary), '$999,999,999') AS total_salary
FROM
  CollegePlaying cp
  JOIN Schools sc ON cp.schoolID = sc.schoolID
  JOIN People p ON cp.playerID = p.playerID
  JOIN Salaries s ON cp.playerID = s.playerID
WHERE
  sc.schoolName = 'Vanderbilt University'
GROUP BY
  p.nameFirst,
  p.nameLast
ORDER BY
  SUM(s.salary) DESC;

-- Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT    CASE
                    WHEN pos = 'OF' THEN 'Outfield'
                    WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
                    WHEN pos IN ('P', 'C') THEN 'Battery'
                    ELSE 'Other'
          END AS position_group,
          SUM(PO) AS total_putouts
FROM      fielding
WHERE     yearID = 2016
GROUP BY  position_group;

-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
SELECT    (yearID / 10) * 10 AS decade,
          ROUND(SUM(SO) * 1.0 / SUM(G), 2) AS strikeouts_per_game,
          ROUND(SUM(HR) * 1.0 / SUM(G), 2) AS home_runs_per_game
FROM      teams
WHERE     yearID >= 1920
GROUP BY  (yearID / 10) * 10
ORDER BY  decade;


-- Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
SELECT    playerID,
          SB,
          CS,
          ROUND(SB * 1.0 / (SB + CS), 3) AS success_rate
FROM      batting
WHERE     yearID = 2016
AND       (SB + CS) >= 20
ORDER BY  success_rate DESC
LIMIT     1;


-- A) From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? B) Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- A:

SELECT    MAX(W) AS max_wins_non_champion
FROM      teams
WHERE     WSWin = 'N'
AND       yearID BETWEEN 1970 AND 2016;



SELECT    MIN(W) AS min_wins_champion
FROM      teams
WHERE     WSWin = 'Y'
AND       yearID BETWEEN 1970 AND 2016;

-- B)

SELECT    MIN(W) AS min_wins_champion_excl_1981
FROM      teams
WHERE     WSWin = 'Y'
AND       yearID BETWEEN 1970 AND 2016
AND       yearID != 1981;



WITH      top_winners AS (
          SELECT    yearID,
                    teamID,
                    W,
                    WSWin
          FROM      teams
          WHERE     yearID BETWEEN 1970 AND 2016
          AND       W = (
                    SELECT    MAX(W)
                    FROM      teams t2
                    WHERE     t2.yearID = teams.yearID
                    )
          )
SELECT    COUNT(*) AS total_years,
          SUM(
          CASE
                    WHEN WSWin = 'Y' THEN 1
                    ELSE 0
          END
          ) AS top_winner_won_ws,
          ROUND(
          SUM(
          CASE
                    WHEN WSWin = 'Y' THEN 1
                    ELSE 0
          END
          ) * 100.0 / COUNT(*),
          2
          ) AS percentage
FROM      top_winners;


-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
SELECT    team,
          park,
          ROUND(attendance * 1.0 / games, 0) AS avg_attendance
FROM      homegames
WHERE     year = 2016
AND       games >= 10
ORDER BY  avg_attendance DESC
LIMIT     5;

SELECT    team,
          park,
          ROUND(attendance * 1.0 / games, 0) AS avg_attendance
FROM      homegames
WHERE     year = 2016
AND       games >= 10
ORDER BY  avg_attendance ASC
LIMIT     5;



-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
WITH tsn_awards AS (
    SELECT 
        playerID,
        yearID,
        lgID
    FROM 
        awardsmanagers
    WHERE 
        awardID = 'TSN Manager of the Year'
),
dual_league_winners AS (
    SELECT 
        playerID
    FROM 
        tsn_awards
    GROUP BY 
        playerID
    HAVING 
        COUNT(DISTINCT lgID) = 2
)
SELECT 
    m.playerID,
    p.nameFirst || ' ' || p.nameLast AS full_name,
    m.teamID,
    m.yearID,
    m.lgID
FROM 
    dual_league_winners d
JOIN 
    managers m ON d.playerID = m.playerID AND EXISTS (
        SELECT 1 FROM tsn_awards a 
        WHERE a.playerID = m.playerID AND a.yearID = m.yearID AND a.lgID = m.lgID
    )
JOIN 
    people p ON m.playerID = p.playerID
ORDER BY 
    full_name, m.yearID;

--EITHER OR..


WITH tsn_awards AS (
    SELECT 
        playerID,
        yearID,
        lgID
    FROM 
        awardsmanagers
    WHERE 
        awardID = 'TSN Manager of the Year'
),
dual_league_winners AS (
    SELECT 
        playerID
    FROM 
        tsn_awards
    GROUP BY 
        playerID
    HAVING 
        COUNT(DISTINCT lgID) = 2
)
SELECT 
    p.nameFirst || ' ' || p.nameLast AS full_name,
    m.teamID,
    m.yearID,
    m.lgID
FROM 
    tsn_awards a
JOIN 
    dual_league_winners d ON a.playerID = d.playerID
JOIN 
    managers m ON a.playerID = m.playerID AND a.yearID = m.yearID AND a.lgID = m.lgID AND m.inseason = 1
JOIN 
    people p ON a.playerID = p.playerID
ORDER BY 
    full_name, m.yearID;



-- Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
SELECT    p.nameFirst,
          p.nameLast,
          b2016.HR AS hr_2016
FROM      people p
JOIN      batting b2016 ON p.playerID = b2016.playerID
AND       b2016.yearID = 2016
WHERE     b2016.HR > 0
AND       (
          SELECT    COUNT(DISTINCT yearID)
          FROM      appearances a
          WHERE     a.playerID = p.playerID
          ) >= 10
AND       b2016.HR = (
          SELECT    MAX(b.HR)
          FROM      batting b
          WHERE     b.playerID = p.playerID
          )
ORDER BY  hr_2016 DESC;

