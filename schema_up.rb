require_relative './lib'

conn = get_db_connection()

schema = <<-HEREDOC
-- Drop table

-- DROP TABLE public.relays;

CREATE TABLE public.relays (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  relay varchar NOT NULL,
  received_event_count int4 NULL DEFAULT 0,
  last_connected_at timestamp NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT relays_pk PRIMARY KEY (id),
  CONSTRAINT relays_un UNIQUE (relay)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.relays for each row execute function set_sys_updated_at();


-- public.tags definition

-- Drop table

-- DROP TABLE public.tags;

CREATE TABLE public.tags (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  "key" varchar NULL,
  value varchar NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT tags_pk PRIMARY KEY (id),
  CONSTRAINT tags_un UNIQUE (key, value)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.tags for each row execute function set_sys_updated_at();


-- public.hashtags definition

-- Drop table

-- DROP TABLE public.hashtags;

CREATE TABLE public.hashtags (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  value varchar NOT NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT hashtags_pk PRIMARY KEY (id),
  CONSTRAINT hashtags_un UNIQUE (value)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.hashtags for each row execute function set_sys_updated_at();


-- public.events definition

-- Drop table

-- DROP TABLE public.events;

CREATE TABLE public.events (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  pubkey varchar NOT NULL,
  created_at timestamptz NULL,
  kind int4 NULL,
  "content" varchar NULL,
  sig varchar NULL,
  event_id varchar NOT NULL,
  event_json jsonb NULL,
  parent_event_id int4 NULL,
  delete_event_id int4 NULL,
  root_event_id int4 NULL,
  ots varchar NULL,
  ots_verified bool NULL DEFAULT false,
  ots_date date NULL,
  pow int4 NULL,
  pow_agg int4 NULL,
  pow_agg_updated_at timestamp NULL,
  descendant_count int4 NULL DEFAULT 0,
  identity_id int4 NOT NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  source_relay_id int4 NULL,
  CONSTRAINT event_un UNIQUE (event_id),
  CONSTRAINT events_pk PRIMARY KEY (id)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.events for each row execute function set_sys_updated_at();


-- public.events_tags definition

-- Drop table

-- DROP TABLE public.events_tags;

CREATE TABLE public.events_tags (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  event_id int4 NOT NULL,
  tag_id int4 NOT NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT events_tags_pk PRIMARY KEY (id),
  CONSTRAINT events_tags_un UNIQUE (event_id, tag_id)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.events_tags for each row execute function set_sys_updated_at();


-- public.follows definition

-- Drop table

-- DROP TABLE public.follows;

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
  "type" varchar NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT follows_pk PRIMARY KEY (id),
  CONSTRAINT follows_un UNIQUE (follower_id, followee_id)
);
CREATE INDEX follows_followee_id_idx ON public.follows USING btree (followee_id, follower_id);
CREATE INDEX follows_id_idx ON public.follows USING btree (id);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.follows for each row execute function set_sys_updated_at();


-- public.identities definition

-- Drop table

-- DROP TABLE public.identities;

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
  pow_agg_updated_at timestamp NULL,
  has_gravatar bool NULL DEFAULT false,
  year_days_active int4 NULL DEFAULT 0,
  first_event_created_at timestamp NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  lud06 varchar NULL,
  CONSTRAINT identities_pk PRIMARY KEY (id),
  CONSTRAINT identities_un UNIQUE (pubkey)
);
CREATE UNIQUE INDEX identities_pubkey_idx ON public.identities USING btree (pubkey);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.identities for each row execute function set_sys_updated_at();


-- public.identities_relays definition

-- Drop table

-- DROP TABLE public.identities_relays;

CREATE TABLE public.identities_relays (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  identity_id int4 NOT NULL,
  relay_id int4 NOT NULL,
  "type" varchar NULL,
  sys_created_at timestamp NOT NULL DEFAULT now(),
  sys_updated_at timestamp NOT NULL DEFAULT now(),
  CONSTRAINT identities_relays_pk PRIMARY KEY (id),
  CONSTRAINT identities_relays_un UNIQUE (identity_id, relay_id)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.identities_relays for each row execute function set_sys_updated_at();


-- public.events_hashtags definition

-- Drop table

-- DROP TABLE public.events_hashtags;

CREATE TABLE public.events_hashtags (
  id int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
  event_id int4 NOT NULL,
  hashtag_id int4 NOT NULL,
  CONSTRAINT events_hashtags_pk PRIMARY KEY (id),
  CONSTRAINT events_hashtags_un UNIQUE (event_id, hashtag_id)
);

-- Table Triggers

create trigger set_sys_updated_at before
update
    on
    public.events_hashtags for each row execute function set_sys_updated_at();


-- public.events foreign keys

ALTER TABLE public.events ADD CONSTRAINT events_identity_fk FOREIGN KEY (identity_id) REFERENCES public.identities(id);
ALTER TABLE public.events ADD CONSTRAINT events_relay_fk FOREIGN KEY (source_relay_id) REFERENCES public.relays(id);


-- public.events_tags foreign keys

ALTER TABLE public.events_tags ADD CONSTRAINT events_tags_fk FOREIGN KEY (tag_id) REFERENCES public.tags(id);
ALTER TABLE public.events_tags ADD CONSTRAINT events_tags_fk_1 FOREIGN KEY (event_id) REFERENCES public.events(id);


-- public.follows foreign keys

ALTER TABLE public.follows ADD CONSTRAINT follows_followee_fk FOREIGN KEY (followee_id) REFERENCES public.identities(id);
ALTER TABLE public.follows ADD CONSTRAINT follows_following_fk FOREIGN KEY (follower_id) REFERENCES public.identities(id);


-- public.identities foreign keys

ALTER TABLE public.identities ADD CONSTRAINT identities_fk FOREIGN KEY (metadata_event_id) REFERENCES public.events(id);


-- public.identities_relays foreign keys

ALTER TABLE public.identities_relays ADD CONSTRAINT identities_relays_fk FOREIGN KEY (identity_id) REFERENCES public.identities(id);
ALTER TABLE public.identities_relays ADD CONSTRAINT identities_relays_fk_1 FOREIGN KEY (relay_id) REFERENCES public.relays(id);


-- public.events_hashtags foreign keys

ALTER TABLE public.events_hashtags ADD CONSTRAINT events_hashtags_fk FOREIGN KEY (event_id) REFERENCES public.events(id);
ALTER TABLE public.events_hashtags ADD CONSTRAINT events_hashtags_fk_1 FOREIGN KEY (hashtag_id) REFERENCES public.hashtags(id);


-- public.boosted_events source

CREATE OR REPLACE VIEW public.boosted_events
AS SELECT e.id,
    e.pubkey,
    e.created_at,
    e.kind,
    e.content,
    e.sig,
    e.event_id,
    e.event_json,
    e.parent_event_id AS parent_id,
    e.delete_event_id,
    i.name
   FROM events e
     JOIN identities i ON i.pubkey::text = e.pubkey::text
  WHERE e.kind = 7;


-- public.events_with_identity source

CREATE OR REPLACE VIEW public.events_with_identity
AS SELECT e.id,
    e.pubkey,
    e.created_at,
    e.kind,
    e.content,
    e.sig,
    e.event_id,
    e.event_json,
    e.parent_event_id AS parent_id,
    e.delete_event_id,
    i.name,
    i.picture
   FROM events e
     JOIN identities i ON i.pubkey::text = e.pubkey::text;


-- public."following" source

CREATE OR REPLACE VIEW public."following"
AS SELECT f.id,
    i1.name AS followername,
    i1.pubkey AS followerpubkey,
    i2.name AS followeename,
    i2.pubkey AS followeepubkey,
    e.created_at AS followingsince,
    i1.pow_agg AS followerpowagg,
    i2.pow_agg AS followeepowagg,
    f.like_count,
    f.reply_count,
    f.mention_count
   FROM follows f
     JOIN identities i1 ON i1.id = f.follower_id
     JOIN identities i2 ON i2.id = f.followee_id
     JOIN events e ON e.id = f.follow_event_id;



CREATE OR REPLACE FUNCTION public.set_sys_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
   IF row(NEW.*) IS DISTINCT FROM row(OLD.*) THEN
      NEW.sys_updated_at = now();
      RETURN NEW;
   ELSE
      RETURN OLD;
   END IF;
END;
$function$
;
HEREDOC
conn.exec(schema)
