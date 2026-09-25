# What Makes a Song Popular on Spotify?

SQL analysis of 114,000 Spotify tracks across 114 genres.

**Business question:** Which genres, artists and audio features are linked to higher popularity, and what separates hits from the rest?

## Key findings
- Only **3.9%** of songs are hits (popularity 70+).
- **Genre sets the ceiling:** 48% of dance tracks are hits, while many niche genres have none.
- Hits almost always have **vocals**, are **twice as likely to be explicit**, and are louder, more danceable and slightly shorter.
- Energy and mood barely differ between hits and other songs.
- **Bad Bunny:** 22 songs, every one a hit.

## Data cleaning
The same song appears under several genres, so the raw 114,000 rows contain only 89,741 unique songs. Songs with popularity 0 (14%) were excluded, leaving 80,393 for analysis.

## Tools & techniques
SQLite · CTEs · aggregation · HAVING · CASE · window functions (ROW_NUMBER, PARTITION BY)

## Files
- `spotify_popularity_project.sql`: all queries
- `Spotify_Popularity_Report.docx`: full write-up with tables and charts

## Data
[Spotify Tracks Dataset](https://www.kaggle.com/datasets/maharshipandya/-spotify-tracks-dataset) (Kaggle)
