require 'pg'
require 'json'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

event_table_create = <<-HEREDOC
CREATE TABLE public.events (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  pubkey varchar NOT NULL,
  created_at timestamptz NULL,
  kind int4 NULL,
  "content" varchar NULL,
  sig varchar NULL,
  event_id varchar NOT NULL,
  event_json jsonb NULL,
  parent_id int4 NULL,
  delete_event_id int4 NULL,
  root_event_id int4 NULL,
  ots varchar NULL,
  ots_verified bool NULL DEFAULT false,
  ots_date date NULL,
  pow int4 NULL DEFAULT 0,
  pow_agg int4 NULL DEFAULT 0,
  pow_updated_at timestamp NULL,
  descendant_count int4 NULL DEFAULT 0,
  identity_id int4 NULL,
  CONSTRAINT event_un UNIQUE (event_id),
  CONSTRAINT events_pk PRIMARY KEY (id)
);
HEREDOC
conn.exec(event_table_create)

identity_table_create = <<-HEREDOC
CREATE TABLE public.identities (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  pubkey varchar NOT NULL,
  "name" varchar NULL,
  about varchar NULL,
  picture varchar NULL,
  recommended_relays varchar NULL,
  metadata_event_id int4 NULL,
  pow int4 NULL,
  nip05 varchar NULL,
  nip05_verified_at timestamp NULL,
  pow_agg int4 NULL DEFAULT 0,
  pow_updated_at timestamp NULL,
  has_gravatar bool NULL DEFAULT false,
  year_days_active int4 NULL DEFAULT 0,
  CONSTRAINT identities_pk PRIMARY KEY (id),
  CONSTRAINT identities_un UNIQUE (pubkey),
  CONSTRAINT identities_fk FOREIGN KEY (metadata_event_id) REFERENCES public.events(id)
);
CREATE UNIQUE INDEX identities_pubkey_idx ON public.identities USING btree (pubkey);
HEREDOC
conn.exec(identity_table_create)

tags_table_create = <<-HEREDOC
CREATE TABLE public.tags (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  "key" varchar NULL,
  value varchar NULL,
  CONSTRAINT tags_pk PRIMARY KEY (id),
  CONSTRAINT tags_un UNIQUE (key, value)
);
HEREDOC
conn.exec(tags_table_create)

events_tags_table_create = <<-HEREDOC
CREATE TABLE public.events_tags (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  event_id int4 NOT NULL,
  tag_id int4 NOT NULL,
  CONSTRAINT events_tags_pk PRIMARY KEY (id),
  CONSTRAINT events_tags_un UNIQUE (event_id, tag_id),
  CONSTRAINT events_tags_fk FOREIGN KEY (tag_id) REFERENCES public.tags(id),
  CONSTRAINT events_tags_fk_1 FOREIGN KEY (event_id) REFERENCES public.events(id)
);
HEREDOC
conn.exec(events_tags_table_create)

follows_table_create = <<-HEREDOC
CREATE TABLE public.follows (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  follower_id int4 NOT NULL,
  followee_id int4 NOT NULL,
  reply_count int4 NULL DEFAULT 0,
  mention_count int4 NULL DEFAULT 0,
  follow_event_id int4 NULL,
  delete_event_id int4 NULL,
  boost_count int4 NULL DEFAULT 0,
  like_count int4 NULL DEFAULT 0,
  CONSTRAINT follows_pk PRIMARY KEY (id),
  CONSTRAINT follows_un UNIQUE (follower_id, followee_id),
  CONSTRAINT follows_followee_fk FOREIGN KEY (followee_id) REFERENCES public.identities(id),
  CONSTRAINT follows_following_fk FOREIGN KEY (follower_id) REFERENCES public.identities(id)
);
CREATE INDEX follows_followee_id_idx ON public.follows USING btree (followee_id, follower_id);
CREATE INDEX follows_id_idx ON public.follows USING btree (id);
HEREDOC
conn.exec(follows_table_create)

events_with_identity_view_create = <<-HEREDOC
CREATE OR REPLACE VIEW public.events_with_identity
AS SELECT e.id,
    e.pubkey,
    e.created_at,
    e.kind,
    e.content,
    e.sig,
    e.event_id,
    e.event_json,
    e.parent_id,
    e.delete_event_id,
    i.name,
    i.picture
   FROM events e
     JOIN identities i ON i.pubkey::text = e.pubkey::text;
HEREDOC
conn.exec(events_with_identity_view_create)

following_view_create = <<-HEREDOC
CREATE OR REPLACE VIEW public.following
AS SELECT f.id,
    i1.name AS followername,
    i1.pubkey AS followerpubkey,
    i2.name AS followeename,
    i2.pubkey AS followeepubkey,
    e.created_at AS followingsince,
    i1.pow_agg AS followerpowagg,
    i2.pow_agg AS followeepowagg
   FROM follows f
     JOIN identities i1 ON i1.id = f.follower_id
     JOIN identities i2 ON i2.id = f.followee_id
     JOIN events e ON e.id = f.follow_event_id;
HEREDOC
conn.exec(following_view_create)
