require_relative './lib'

conn = get_db_connection

# Note: We need parent_event_id to be populated for this to work
results = conn.exec('SELECT f.id, i.pubkey as follower_pubkey, i2.pubkey as followee_pubkey
FROM follows f
join identities i on i.id = f.follower_id
join identities i2 on i2.id  = f.followee_id
WHERE delete_event_id IS NULL')

results.each do |row|

  follower = row['follower_pubkey']
  followee = row['followee_pubkey']

  results2 = conn.exec_params("select Count(*) from events e
join events e2 on e2.parent_event_id = e.id
where
e2.delete_event_id is null and
e2.kind = 1 and
e2.parent_event_id is not null and
e2.pubkey = $1 and
e.delete_event_id is null and
e.pubkey = $2", [follower, followee]).first

  reply_count = results2["count"]

  update_follows_reply_count(conn, row["id"], reply_count)

end
