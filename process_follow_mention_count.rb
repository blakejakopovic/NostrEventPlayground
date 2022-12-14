require_relative './lib'

conn = get_db_connection

# MENTIONS: Get all p tags between User A (e.pubkey) and  User B (t.value)
results = conn.exec('SELECT f.id, i.pubkey as follower_pubkey, i2.pubkey as followee_pubkey
FROM follows f
join identities i on i.id = f.follower_id
join identities i2 on i2.id  = f.followee_id
WHERE delete_event_id IS NULL')

results.each do |row|

  follower = row['follower_pubkey']
  followee = row['followee_pubkey']

  results2 = conn.exec_params("select COUNT(*) from tags t
join events_tags et on et.tag_id = t.id
join events e on e.id = et.event_id
where e.pubkey = $1
and t.key = 'p' and t.value = $2
and e.kind = 1", [follower, followee]).first

  mention_count = results2["count"]

  update_follows_mention_count(conn, row["id"], mention_count)

end
