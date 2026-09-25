-- ============================================
-- What Makes a Song Popular on Spotify?
-- ============================================
-- Business question: Which genres, artists and audio features
-- are linked to higher popularity, and what separates hits
-- from the rest?
-- Tool: SQLite (DB Browser for SQLite)
-- Data: Spotify Tracks Dataset by maharshipandya (Kaggle)

-- Cleaning: rename columns, set types, drop header row
CREATE TABLE tracks_new AS SELECT
  CAST(field1 AS INTEGER)  AS row_num,
  field2                   AS track_id,
  NULLIF(field3,'')        AS artists,
  NULLIF(field4,'')        AS album_name,
  NULLIF(field5,'')        AS track_name,
  CAST(field6 AS INTEGER)  AS popularity,
  CAST(field7 AS INTEGER)  AS duration_ms,
  CASE field8 WHEN 'True' THEN 1 ELSE 0 END AS explicit,
  CAST(field9 AS REAL)     AS danceability,
  CAST(field10 AS REAL)    AS energy,
  CAST(field11 AS INTEGER) AS "key",
  CAST(field12 AS REAL)    AS loudness,
  CAST(field13 AS INTEGER) AS mode,
  CAST(field14 AS REAL)    AS speechiness,
  CAST(field15 AS REAL)    AS acousticness,
  CAST(field16 AS REAL)    AS instrumentalness,
  CAST(field17 AS REAL)    AS liveness,
  CAST(field18 AS REAL)    AS valence,
  CAST(field19 AS REAL)    AS tempo,
  CAST(field20 AS INTEGER) AS time_signature,
  field21                  AS track_genre
FROM tracks
WHERE rowid > 1;
DROP TABLE tracks;
ALTER TABLE tracks_new RENAME TO tracks;

-- Exploration: duplicates and popularity spread
SELECT COUNT(*) AS rows,
       COUNT(DISTINCT track_id) AS unique_tracks,
       COUNT(DISTINCT track_genre) AS genres
FROM tracks;

SELECT CASE
         WHEN popularity = 0 THEN '0'
         WHEN popularity < 20 THEN '1-19'
         WHEN popularity < 40 THEN '20-39'
         WHEN popularity < 60 THEN '40-59'
         WHEN popularity < 80 THEN '60-79'
         ELSE '80-100'
       END AS popularity_band,
       COUNT(*) AS tracks
FROM tracks
GROUP BY popularity_band
ORDER BY MIN(popularity);

-- Base table: one row per unique song, popularity > 0
DROP TABLE IF EXISTS songs;
CREATE TABLE songs AS
SELECT track_id, artists, album_name, track_name,
       MAX(popularity) AS popularity,
       duration_ms, explicit, danceability, energy, "key",
       loudness, mode, speechiness, acousticness,
       instrumentalness, liveness, valence, tempo
FROM tracks
WHERE popularity > 0
GROUP BY track_id;

-- Q1: genres by hit rate (change DESC to ASC for bottom 10)
SELECT track_genre,
       COUNT(*) AS tracks,
       ROUND(AVG(popularity), 1) AS avg_popularity,
       SUM(popularity >= 70) AS hits,
       ROUND(100.0 * SUM(popularity >= 70) / COUNT(*), 1) AS hit_rate
FROM tracks
WHERE popularity > 0
GROUP BY track_genre
ORDER BY hit_rate DESC
LIMIT 10;

-- Q2: audio features of hits vs the rest
SELECT CASE WHEN popularity >= 70 THEN 'Hit' ELSE 'Rest' END AS grp,
       COUNT(*) AS songs,
       ROUND(AVG(danceability), 3) AS danceability,
       ROUND(AVG(energy), 3) AS energy,
       ROUND(AVG(valence), 3) AS valence,
       ROUND(AVG(acousticness), 3) AS acousticness,
       ROUND(AVG(instrumentalness), 3) AS instrumentalness,
       ROUND(AVG(speechiness), 3) AS speechiness,
       ROUND(AVG(loudness), 2) AS loudness,
       ROUND(AVG(duration_ms) / 60000.0, 2) AS minutes,
       ROUND(100.0 * AVG(explicit), 1) AS explicit_pct
FROM songs
GROUP BY grp;

-- Q3: most consistent hit-making artists (at least 5 songs)
SELECT artists,
       COUNT(*) AS songs,
       ROUND(AVG(popularity), 1) AS avg_popularity,
       SUM(popularity >= 70) AS hits
FROM songs
GROUP BY artists
HAVING COUNT(*) >= 5
ORDER BY avg_popularity DESC
LIMIT 10;

-- Q4: top song per genre
WITH ranked AS (
  SELECT track_genre, track_name, artists, popularity,
         ROW_NUMBER() OVER (PARTITION BY track_genre
                            ORDER BY popularity DESC) AS rn
  FROM tracks
)
SELECT track_genre, track_name, artists, popularity
FROM ranked
WHERE rn = 1
ORDER BY popularity DESC
LIMIT 15;

-- ============================================
-- KEY FINDINGS
-- ============================================
-- 1. 114,000 rows but only 89,741 unique songs. 14% have
--    popularity 0 and were excluded, leaving 80,393 songs.
-- 2. Hits (popularity 70+) are rare: 3.9% of songs.
-- 3. Genre sets the ceiling. Dance (48%) and rock (42%) have the
--    highest hit rates; many niche genres have zero hits.
--    Forro and gospel average ~42 popularity yet never produce hits.
-- 4. Hits have vocals (instrumentalness 0.034 vs 0.185), are twice
--    as likely to be explicit (17.9% vs 8.3%), louder, more
--    danceable, less acoustic and ~15s shorter. Energy and mood
--    barely differ.
-- 5. Bad Bunny: 22 songs, all hits, averaging 85.4 popularity.
--
-- LIMITATIONS
-- - Associations, not causes; genre partly drives feature gaps.
-- - Genre labels are loose (one song can top four genres).
-- - Collaborations are stored as one artist string.
-- - Popularity is a snapshot from around late 2022.
