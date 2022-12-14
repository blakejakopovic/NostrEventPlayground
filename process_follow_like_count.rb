require_relative './lib'

conn = get_db_connection

# TODO: Follows may be implicit or explicit (kind=3 OR in the wild interactions)

# For each follow relation
#   0. relation = 0
#   1. get all events where pubkey = followee
#   2. check for p tags that contain following
#   3. if match, relation += 1
#   4. update relationship with score

#   5. get all following events which e tag of followee
#   6. if match, relation += 1
#   7. update relationship with score

# Maybe a ratio of inbound vs outbound relationships
# Maybe include kind=4 in the future?

# TODO: Filter out duplicate likes for the same event

# LIKES: Get all p reaction tags between User A (e.pubkey) and  User B (t.value)
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
and e.delete_event_id is null
and t.key = 'p' and t.value = $2
and e.kind = 7
and (e.content = '' or e.content = '+' or e.content = '❤️')", [follower, followee]).first

  like_count = results2["count"]

  update_follows_like_count(conn, row["id"], like_count)

end
