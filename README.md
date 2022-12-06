# Nostr Event Playground

A repo to import, process and query Nostr events. This repo is very must a playground and can change in any way, at any time for now. In future it may stablise and may adopt an ORM, schema migrations, better ways to process data and events - but for now it's just consolidating base knowledge and approaches.

Performance is a consideration, however to start we're focusing on getting it done and accuracy.

*IMPORTANT:* This code base is filled with TODOs and lots of half finished data processing. It still needs a lot of work (read: love), however it should help become a useful resource over time.

## Getting Started

1. Clone repo
```shell
git clone https://github.com/blakejakopovic/NostrEventPlayground
cd NostrEventPlayground
```

2. Install required Rubygems
```shell
bundle install
```

3. Install Postgres and optionally create a `nostr` database
```shell
psql postgres
postgres=> CREATE DATABASE nostr;
```

4. Create the postgres database table schemas
```shell
ruby schema_up.rb
```

5. Download an `events.json` of Nostr events you wish to import

6. Import events (`events.json` in root directory)
```shell
ruby import_events.rb
```

7. Run whatever `process` scripts you need

## List of tables and views
### Tables
```
events - all events
events_tags - event and tag m2m table
follows - events and identities m2m table
identities - event pubkey sourced identities
tags - event tag list
```

### Views
```
events_with_identity - events joined with identity (pubkey)
following - follower and followee joined view
```


## List of processing scripts (in order of required execution)
```shell
schema_up.rb - Bootstrap postgres with required tables

import_events.rb - Imports a JSON file with an array of Nostr events (see example file)

process_event_deletions.rb - (!! Important !!) Set events.delete_event_id field if a deletion event (kind=5) was found. If you do not run this, the following processing steps may include events that should be ignored.
process_event_e_tags.rb - (optional) Process event parent_id event using e-tag data
process_event_pow.rb - (optional) Calculate event PoW (leading zero bits)
process_event_pow_agg.rb - (optional - SLOW!) Calculate an event and sum its children PoW (leading zero bits)
process_event_tags.rb - (optional) Populate the tags table and m2m records

process_identity.rb - Create identity records for each unique event pubkey
process_identity_metadata.rb - (optional) Populate Identity table meta fields using kind=0 events
process_identity_nip05.rb - (optional) Populate Identity table nip05 fields after validating
process_identity_nip05_gravatar.rb - (optional) Populate Identity has_gravatar field after validating existing (using NIP-05 email). Note: Requires Wordpress API key for gravatar.
process_identity_pow.rb - (optional) Populate Identity pubkey pow
process_identity_pow_agg.rb - (optional) Populate the aggregate sum of all events for a pubkey
process_identity_year_days_active.rb - (optional) Populate days active (days with an event created_at) during the past (rolling) year

process_following.rb - (optional) Populate m2m follow table using kind=3 event data
process_follow_boost_count.rb - (optional) Populate followee event boosts of an identity they are following
process_follow_like_count.rb - (optional) Populate followee event likes of an identity they are following
process_follow_reply_count.rb - (optional) Populate followee event reply of an identity they are following
```


## NIP Specific Examples

### NIP-01 - Basic protocol flow description

Related scripts
```shell
import_events.rb
process_identity.rb
process_identity_metadata.rb
process_event_e_tags.rb
process_event_tags.rb
```

Example Queries
```sql

```


### NIP-02 - Contact List and Petnames

Related scripts
```shell
process_following.rb
```

Example Queries
```sql
-- Get follower identities for pubkey
select f.id, i1.* from follows f
  inner join identities i1 on i1.id = f.follower_id
  inner join identities i2 on i2.id = f.followee_id
   where i2.pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b'

-- Count followers for pubkey
select count(*) from follows f
inner join identities i1 on i1.id = f.followee_id
where i1.pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b'

-- Get following identities for pubkey
select f.id, i2.* from follows f
  inner join identities i1 on i1.id = f.follower_id
  inner join identities i2 on i2.id = f.followee_id
   where i1.pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b'

-- Count following for pubkey
select count(*) from follows f
inner join identities i1 on i1.id = f.follower_id
where i1.pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b'
```

### NIP-03 - OpenTimestamps Attestations for Events

Related scripts
```shell
# process_event_ots.rb is missing. It should import and validate (but I have no ots data yet)
```

Example Queries
```sql
-- Query for events with OTS (migrate to processing script.. but quick and dirty)
select * from events where CAST(event_json AS VARCHAR) like '%"ots":%'
-- OR
select * from events where ots IS NOT NULL
select * from events where ots IS NOT NULL AND ots_verified = true
```

### NIP-05 - Mapping Nostr keys to DNS-based internet identifiers

Related scripts
```shell
process_identity_nip05.rb
process_identity_nip05_gravatar.rb
```

Example Queries
```sql
-- Query for all nip05 events
select * from events where kind = 0 and content like '%"nip05":%'
-- OR
select DISTINCT on (pubkey) pubkey, content from events where kind = 0 and content like '%"nip05":%' AND delete_event_id IS NULL ORDER BY pubkey, created_at desc

-- Query for all identities with verified nip5
select * from identities where nip05 IS NOT NULL AND nip05_verified_at IS NOT NULL
```

Note: The `process_identity_nip05.rb` script removes the nip05 \_@ prefix (as per the NIP), which means it will be a root domain, and not a full email.


### NIP-08 - Handling Mentions

Related scripts
```
N/A
```

Example Queries
```sql
-- TODO: Count number of mentions for a user?
-- TODO: Show all mentions for a pubkey
```


### NIP-09 - Event Deletion

Related scripts
```shell
process_event_deletions.rb
```

Example Queries
```sql

```

### NIP-12 - Generic Tag Queries

Related scripts
```shell

```

Example Queries
```sql
-- Get event with its tags
-- TODO: Needs work
select e.*, t.*
from events e
inner join events_tags et on et.event_id = e.id
inner join tags t on et.tag_id = t.id
where e.id = 22630
```


### NIP-13 - Proof of Work (PoW)

Related scripts
```shell
process_event_pow.rb
process_event_pow_agg.rb

process_identity_pow.rb
process_identity_pow_agg.rb
```

Note that `process_event_pow_agg.rb` is pretty slow and has a bug atm.

Example Queries
```sql
-- Events sorted by highest (event id) PoW
select * from events order by pow desc

-- TODO: Event pow_agg is half working.. needs tweaks before we query it
select * from events order by pow_agg desc

-- Identities softed by highest (pubkey) PoW
-- Note: This can be NULL as we may have only seen a pubkey (e.g. in tags), but no metadata event
select * from identities where pow is not null order by pow desc

-- For identities but aggregate POW (all their events)
## TODO: Maybe add in their identity pow to agg pow, as it should count
select * from identities where pow_agg is not NULL order by pow_agg desc

-- Who has the highest pubkey PoW?
select name,pow from identities order by pow desc

-- Who has the highest agg Pow?
select name,pow_agg from identities order by pow_agg desc
```

### NIP-14 - Subject tag in Text events

Related scripts
```
N/A
```

Example Queries
```sql
-- Query events with a subject tag
-- TODO: Make more performant and accurate (only use tags directly) - use tags table
select * from events where CAST(event_json AS VARCHAR)  like '%["subject",%'
```


### NIP-16 - Replaceable Events (replace if newer timestamp)

Related scripts
```
N/A
```

Example Queries
```sql
-- Query replacable events for latest version
-- TODO: Need to handle the case where the latest is deleted,
SELECT DISTINCT on (pubkey) pubkey,* FROM events WHERE kind > 9999 and kind < 20000 AND delete_event_id IS NULL ORDER BY pubkey, created_at desc
```


### NIP-25 - Reactions

Related scripts
```shell
process_follow_like_count.rb
```

Example Queries
```sql
-- Get identity likes events
select * from events where kind = 7 and (content = "" or content = "+") and pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b' and delete_event_id IS NULL

-- Get likes for specific event
select * from events where kind = 7 and (content = '' or content = '+') and parent_id in (select id from events where event_id = 'c04555840d263dda0a414c1a3be9d648a7c9e99be80999b5acd0cdf987141f6f' and delete_event_id IS NULL) and delete_event_id IS NULL

-- Get deleted likes (requires deleted_at field)
select * from events where kind = 7 and (content = "" or content = "+") and delete_event_id IS NULL

-- Get dislikes for event
select * from events where kind = 7 and content = '-' and parent_id in (select id from events where event_id = 'c04555840d263dda0a414c1a3be9d648a7c9e99be80999b5acd0cdf987141f6f' and delete_event_id IS NULL) and delete_event_id IS NULL

-- Get event Boosts
SELECT * FROM events WHERE kind = 7 AND delete_event_id IS NULL AND (content = '' OR content IS NULL) AND parent_id IS NOT NULL

```


### NIP-28 - Public Chat

Related scripts
```shell

```

Example Queries
```sql
-- Get Channels
select * from events where kind = 40 and delete_event_id IS NULL

-- Get Channel Posts (!! Need to review and perhaps look at using tags in query)
select * from events where kind = 42 and delete_event_id IS null and CAST(event_json AS VARCHAR) LIKE '%["e",%"a988ce2be497289aedc3f8dbf1f73ab10c919017d6bf913d6df6060da9850395"%'
-- OR
select * from events where kind = 42 and delete_event_id IS null and parent_id = (select id from events where event_id = 'a988ce2be497289aedc3f8dbf1f73ab10c919017d6bf913d6df6060da9850395')

-- Get top level channel messages for all channels
select * from events where kind = 42 and delete_event_id is null and parent_id in (select id from events where kind = 40 and delete_event_id IS null group by id)

```


## General query examples

```sql

-- Basic Public Timeline
SELECT * FROM events WHERE kind = 1 AND delete_event_id IS NULL AND content != '' AND content IS NOT NULL

-- TODO: Get Timeline as pubkey (see their timeline, based on who they follow)

-- Query event jsonb directly
SELECT * FROM events WHERE event_json->>'pubkey' = '24e37c1e5b0c8ba8dde2754bcffc63b5b299f8064f8fb928bcf315b9c4965f3b';

-- TODO: (WIP) Get thread from starting event id (ancestors + descendants)
WITH recursive
    -- starting node(s)
    starting (id, parent_id, event_id, pubkey, content) AS
    (
      SELECT e.id, e.parent_id,e.event_id, e.pubkey, e.content, id::TEXT path
      FROM events AS e
      WHERE e.id = 38181
    ),
    descendants (id, parent_id, event_id, pubkey, content) AS
    (
      SELECT e.id, e.parent_id,e.event_id, e.pubkey, e.content, id::TEXT path
      FROM starting AS e
      UNION ALL
      SELECT e.id, e.parent_id,e.event_id, e.pubkey, e.content, d.path || ',' || d.id
      FROM events AS e JOIN descendants AS d ON e.parent_id = d.id
    ),
    ancestors (id, parent_id, event_id, pubkey, content) AS
    (
      SELECT e.id, e.parent_id, e.event_id, e.pubkey, e.content, id::TEXT path
      FROM events AS e
      WHERE e.id IN (SELECT e.parent_id FROM starting)
      UNION ALL
      SELECT e.id, e.parent_id, e.event_id, e.pubkey, e.content, a.path || ',' || a.id
      FROM events AS e JOIN ancestors AS a ON e.id = a.parent_id
    )
TABLE ancestors
UNION ALL
TABLE descendants
Order by path asc

```


## Analytical and Statistical Examples

```sql

-- Show top users by days active past year
select pubkey,name,year_days_active from identities order by year_days_active desc


-- TODO: Query for replies to old events (perhaps where event > 30 days)

-- Who likes someone they follows posts the most?
SELECT i."name" as Follower, i2."name" as Following, f.like_count as follower_like_count_aka_stalker_rating
from follows f
join identities i on i.id = f.follower_id
join identities i2 on i2.id  = f.followee_id
order by like_count desc


-- Who replies to someone they follow the most?
SELECT i."name" as Follower, i2."name" as Following, f.reply_count as follower_reply_count_aka_interaction_rating
from follows f
join identities i on i.id = f.follower_id
join identities i2 on i2.id  = f.followee_id
order by reply_count desc

-- How many times has a user liked another user?
select * from tags t
join events_tags et on et.tag_id = t.id
join events e on e.id = et.event_id
where e.pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b'
and t.key = 'p' and t.value = '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245'
and e.kind = 7
and (e.content = '' or e.content = '+' or e.content = '❤️')

-- How many times has a user disliked another user?
select * from tags t
join events_tags et on et.tag_id = t.id
join events e on e.id = et.event_id
where e.pubkey = 'b2dd40097e4d04b1a56fb3b65fc1d1aaf2929ad30fd842c74d68b9908744495b'
and t.key = 'p' and t.value = '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245'
and e.kind = 7
and e.content = '-'

-- TODO: Popular hashtags past 24 hours

-- Who has the most followers?
select COUNT(*) as count, i.name from follows f
join identities i on i.id = f.followee_id
group by followee_id, i.name order by count desc

-- Who is following the most people?
```
