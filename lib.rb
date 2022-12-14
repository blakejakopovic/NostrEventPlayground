require 'pg'

# TODO: Drop conn fn input and memoize connection and make implicit
def get_db_connection()
  return PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )
end

def create_event(conn, id, pubkey, created_at, kind, content, sig, event_json, identity_id)
  return conn.exec_params(
      "INSERT INTO events (event_id, pubkey, created_at, kind, content, sig, event_json, identity_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT DO NOTHING;",
      [id, pubkey, created_at, kind, content, sig, event_json, identity_id])
end

def get_event(conn, event_id)
  return conn.exec_params("SELECT * FROM events WHERE event_id = $1", [event_id]).first
end

def update_event_with_deleted_event(conn, delete_event_id, parent_event_id)
  conn.exec_params("UPDATE events SET delete_event_id=$1 WHERE id=$2", [delete_event_id, parent_event_id])
end

def update_event_with_parent_event(conn, child_id, parent_event_id)
  conn.exec_params("UPDATE events SET parent_event_id=$1 WHERE id=$2", [parent_event_id, child_id])
end

def update_event_with_root_event(conn, child_id, root_event_id)
  conn.exec_params("UPDATE events SET root_event_id=$1 WHERE id=$2", [root_event_id, child_id])
end

def create_identity(conn, pubkey)
  conn.exec_params("WITH e AS(
    INSERT INTO identities (pubkey)
           VALUES ($1)
    ON CONFLICT DO NOTHING
    RETURNING id
)
SELECT * FROM e
UNION
    SELECT id FROM identities WHERE pubkey=$1", [pubkey]).first
end

def get_identity(conn, pubkey)
  return conn.exec_params("SELECT * FROM identities WHERE pubkey=$1", [pubkey]).first
end

def update_identity_with_metadata(conn, pubkey, name, about, picture, lud06, metadata_event_id)
  conn.exec_params("UPDATE identities SET name=$1, about=$2, picture=$3, lud06=$4, metadata_event_id=$5 WHERE pubkey=$6", [name, about, picture, lud06, metadata_event_id, pubkey])
end

def update_identity_nip05(conn, identity_pubkey, nip05, nip05_verified_at)
  conn.exec_params("UPDATE identities SET nip05=$1, nip05_verified_at=$2 WHERE pubkey=$3",
                   [nip05, nip05_verified_at, identity_pubkey]).first
end

def update_identity_gravatar(conn, identity_pubkey, has_gravatar)
  conn.exec_params("UPDATE identities SET has_gravatar=$1 WHERE pubkey=$2",
                   [has_gravatar, identity_pubkey]).first
end

def update_identity_pow(conn, identity_id, pow)
  conn.exec_params("UPDATE identities SET pow=$1 WHERE id=$2",
                   [pow, identity_id]).first
end

def update_identity_pow_agg(conn, identity_id, pow)
  conn.exec_params("UPDATE identities SET pow_agg=$1, pow_agg_updated_at=$2 WHERE id=$3",
                   [pow, DateTime.now(), identity_id]).first
end

def update_identity_with_year_days_active(conn, pubkey, count)
  conn.exec_params("UPDATE identities SET year_days_active=$1 WHERE pubkey=$2", [count, pubkey])
end

def update_identity_with_first_event_created_at(conn, pubkey, first_event_created_at)
  conn.exec_params("UPDATE identities SET first_event_created_at=$1 WHERE pubkey=$2", [first_event_created_at, pubkey])
end

def update_event_pow(conn, event_id, pow)
  conn.exec_params("UPDATE events SET pow=$1 WHERE event_id=$2",
                   [pow, event_id]).first
end

def update_event_pow_agg(conn, event_id, pow, descendant_count)
  conn.exec_params("UPDATE events SET pow_agg=$1, pow_agg_updated_at=$2, descendant_count=$3 WHERE id=$4",
                   [pow, DateTime.now(), descendant_count, event_id]).first
end

def add_follow_relationship(conn, follower_id, followee_id, follow_event_id, type)
  # If exists, upgrade to explicit, but don't downgrade to implicit
  if type == 'explicit'
    conn.exec_params("INSERT INTO follows (follower_id, followee_id, follow_event_id, type) VALUES ($1, $2, $3, $4) ON CONFLICT (follower_id, followee_id) DO UPDATE SET type = 'explicit'", [follower_id, followee_id, follow_event_id, type])
  else
    conn.exec_params("INSERT INTO follows (follower_id, followee_id, follow_event_id, type) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING", [follower_id, followee_id, follow_event_id, type])
  end
end

def update_follows_like_count(conn, id, count)
  conn.exec_params("UPDATE follows SET like_count=$1 WHERE id=$2", [count, id])
end

def update_follows_boost_count(conn, id, count)
  conn.exec_params("UPDATE follows SET boost_count=$1 WHERE id=$2", [count, id])
end

def update_follows_reply_count(conn, id, count)
  conn.exec_params("UPDATE follows SET reply_count=$1 WHERE id=$2", [count, id])
end

def update_follows_mention_count(conn, id, count)
  conn.exec_params("UPDATE follows SET mention_count=$1 WHERE id=$2", [count, id])
end

def get_tag(conn, key, value)
  conn.exec_params("SELECT id FROM tags WHERE key=$1 AND value=$2", [key, value])
end

def create_tag(conn, key, value)
  conn.exec_params("WITH t AS(
    INSERT INTO tags (key, value)
           VALUES ($1, $2)
    ON CONFLICT DO NOTHING
    RETURNING id
)
SELECT * FROM t
UNION
    SELECT id FROM tags WHERE key=$1", [key, value]).first
end

def create_event_tag(conn, event_id, tag_id)
  conn.exec_params("INSERT INTO events_tags (event_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING returning id", [event_id, tag_id])
end

def create_hashtag(conn, value)
  conn.exec_params("WITH ht AS(
    INSERT INTO hashtags (value)
           VALUES ($1)
    ON CONFLICT DO NOTHING
    RETURNING id
)
SELECT * FROM ht
UNION
    SELECT id FROM hashtags WHERE value=$1", [value]).first
end

def create_event_hashtag(conn, event_id, hashtag_id)
  conn.exec_params("INSERT INTO events_hashtags (event_id, hashtag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING returning id", [event_id, hashtag_id])
end

def create_relay(conn, relay)
  conn.exec_params("WITH r AS(
    INSERT INTO relays (relay)
           VALUES ($1)
    ON CONFLICT DO NOTHING
    RETURNING id
)
SELECT * FROM r
UNION
    SELECT id FROM relays WHERE relay=$1", [relay]).first
end

def create_identity_relay(conn, identity_id, relay_id, type)
  conn.exec_params("INSERT INTO identities_relays (identity_id, relay_id, type) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING returning id", [identity_id, relay_id, type])
end

def update_relay_last_connected(conn, relay_id)
  conn.exec_params("UPDATE relays SET last_connected_at=$1 WHERE id=$2",
                   [DateTime.now(), relay_id]).first
end

def get_event_p_tags(event)
  results = []

  # TODO: Perhaps ignore #p
  tag_list = ['p', '#p']
  tags = event['tags']
  tags.select {|t| tag_list.include?(t[0]) }.each do |tag|
    results.append(tag)
  end
end

# Takes multiple p-tags with optional multi-values and returns
def get_p_tag_pubkeys(tags)
  tags.map { |tag|
    tag[1..]
  }
  .flatten
  .map{ |pubkey| pubkey.downcase }
  .uniq
end

def get_event_e_tags(event)
  results = []

  # TODO: Perhaps ignore #e
  tag_list = ['e', '#e']
  tags = event['tags']
  tags.select {|t| tag_list.include?(t[0]) }.each do |tag|
    results.append(tag)
  end
end

# TODO: Add validation for delegation
def get_event_delegation_tag(event)
  return event['tags'].filter {|t| t[0] == 'delegation' and t.length() == 4 }.first
end

def hex_to_bytes(s)
  s.scan(/.{1,2}/).map{|b| b.to_i(16)}
end

def zero_bits(b)
    n = 0

    if b == 0
      return 8
    end

    while true do
        b >>= 1

        if b != 0
          n += 1
        else
          break
        end
    end

    return 7 - n;
end

def count_leading_zero_bits(hash)
  total = 0

  for i in 0...32 do
    bits = zero_bits(hash[i]);
    total += bits;

    break if (bits != 8)
  end

  return total
end

def get_pow(s)
  count_leading_zero_bits(hex_to_bytes(s))
end
