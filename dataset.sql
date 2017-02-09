CREATE TABLE data (
    username text,
    vote integer,
    subreddit text DEFAULT '',
    title text DEFAULT '',
    content text
);

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

INSERT INTO processeddata (title, subreddit, content, vote, users) SELECT regexp_replace(title, E'[\\n\\r|\\t]+', ' ', 'g' ) AS title, subreddit, content, vote, string_agg(username, ', ') AS users
FROM data WHERE title <> '' AND title IS NOT NULL GROUP BY title, subreddit, content, vote ORDER BY random();

INSERT INTO allusers SELECT DISTINCT s.users
FROM processeddata t, unnest(string_to_array(t.users, ',')) s(users);

/*
	We used random order before, everything is fine :)
	878779 titles where vote=1 (upvote). TODO: Function that holds this number so we don't update it ourselves.
	70%ish training data = 615000 first rows
	20%ish validation data = 615001 - 790000
	10%ish test data = 790001 - 878779
*/

\copy (select regexp_replace(title, '^\s+', '') AS title, users FROM processeddata where vote=1 AND ID < 615001) to '~/Desktop/training_data.csv' With CSV;
\copy (select regexp_replace(title, '^\s+', '') AS title, users FROM processeddata where vote=1 AND ID > 615000 AND ID < 790001) to '~/Desktop/validation_data.csv' With CSV;
\copy (select regexp_replace(title, '^\s+', '') AS title, users FROM processeddata where vote=1 AND ID > 790000) to '~/Desktop/testing_data.csv' With CSV;
