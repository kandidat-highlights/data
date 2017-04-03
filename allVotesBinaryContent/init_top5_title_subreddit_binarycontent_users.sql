CREATE TABLE data (
    username text,
    vote integer,
    subreddit text DEFAULT '',
    title text DEFAULT '',
    content text
);
-- change path to the file.
\copy data from '~/Desktop/original_data_9feb.csv' with NULL AS ' ' csv;

CREATE TABLE processeddata (
	id SERIAL NOT NULL,--This will be used to split training/valid data.select
	title text,
	subreddit text,
	content text,
	vote integer,
	users text
);

CREATE TABLE allusers(
	users text
);
-- Change the number after "desc limit" in order to choose how many users you want
INSERT INTO processeddata (title, subreddit, content, vote, users) SELECT regexp_replace(title, E'[\\n\\r|\\t]+', ' ', 'g' ) AS title, subreddit, regexp_replace(content, E'[\\n\\r|\\t]+', ' ', 'g' ) as content, vote, string_agg(username, ', ') AS users
FROM data WHERE title <> '' AND title IS NOT NULL AND username in (select username from data group by username order by count(username) desc limit 5) 
GROUP BY title, subreddit, content, vote ORDER BY random();

/*
	We used random order before, everything is fine :)
	70%ish training data 
	20%ish validation data
	10%ish test data

*/
\copy (select regexp_replace(title, '^\s+', '') AS title, subreddit, CASE WHEN content = '' OR content = NULL THEN 0 ELSE 1 END, users FROM processeddata WHERE ID < floor((select max(id) from processeddata) * 0.7)) to '~/Desktop/training_data_top_5_subreddit_allvotes_binarycontent.csv' With CSV;
\copy (select regexp_replace(title, '^\s+', '') AS title, subreddit, CASE WHEN content = '' OR content = NULL THEN 0 ELSE 1 END, users FROM processeddata WHERE ID > floor((select max(id) from processeddata) * 0.7)+1 AND ID < floor((select max(id) from processeddata) * 0.9)) to '~/Desktop/validation_data_top_5_subreddit_allvotes_binarycontent.csv' With CSV;
\copy (select regexp_replace(title, '^\s+', '') AS title, subreddit, CASE WHEN content = '' OR content = NULL THEN 0 ELSE 1 END, users FROM processeddata WHERE ID > floor((select max(id) from processeddata) * 0.9) +1) to '~/Desktop/testing_data_top_5_subreddit_allvotes_binarycontent.csv' With CSV;
