# require_relative './lib'

def get_event(conn, event_id)
  return conn.exec_params("SELECT * FROM events WHERE event_id = $1", [event_id]).first
end

def update_event_with_deleted_event(conn, delete_event_id, parent_id)
  conn.exec_params("UPDATE events SET delete_event_id=$1 WHERE id=$2", [delete_event_id, parent_id])
end

def update_event_with_parent(conn, child_id, parent_id)
  conn.exec_params("UPDATE events SET parent_id=$1 WHERE event_id=$2", [parent_id, child_id])
end

def get_identity(conn, pubkey)
  return conn.exec_params("SELECT * FROM identities WHERE pubkey=$1", [pubkey]).first
end

def update_identity_with_metadata(conn, pubkey, name, about, picture, recommended_relays, metadata_event_id)
  conn.exec_params("UPDATE identities SET name=$1, about=$2, picture=$3, recommended_relays=$4, metadata_event_id=$5 WHERE pubkey=$6", [name, about, picture, recommended_relays, metadata_event_id, pubkey])
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
  conn.exec_params("UPDATE identities SET pow_agg=$1 WHERE id=$2",
                   [pow, identity_id]).first
end

def update_identity_with_year_days_active(conn, pubkey, count)
  conn.exec_params("UPDATE identities SET year_days_active=$1 WHERE pubkey=$2", [count, pubkey])
end

def update_event_pow(conn, event_id, pow)
  conn.exec_params("UPDATE events SET pow=$1 WHERE event_id=$2",
                   [pow, event_id]).first
end

def update_event_pow_agg(conn, event_id, pow, descendant_count)
  conn.exec_params("UPDATE events SET pow_agg=$1, descendant_count=$2 WHERE id=$3",
                   [pow, descendant_count, event_id]).first
end

def add_follow_relationship(conn, follower_id, followee_id, follow_event_id)
  conn.exec_params("INSERT INTO follows (follower_id, followee_id, follow_event_id) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING", [follower_id, followee_id, follow_event_id])
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

def get_tag(conn, key, value)
  conn.exec_params("SELECT id FROM tags WHERE key=$1 AND value=$2", [key, value])
end

def create_tag(conn, key, value)
  conn.exec_params("INSERT INTO tags (key, value) VALUES ($1, $2) ON CONFLICT DO NOTHING", [key, value])
end

def create_event_tag(conn, event_id, tag_id)
  conn.exec_params("INSERT INTO events_tags (event_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING returning id", [event_id, tag_id])
end

def get_event_p_tags(event)
  results = []

  tag_list = ['p', '#p']
  tags = event['tags']
  tags.select {|t| tag_list.include?(t[0]) }.each do |tag|
    results.append(tag)
  end
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
