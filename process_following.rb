require 'json'
require_relative './lib'

conn = get_db_connection()

# TODO: Process unfollows or deleted follow events? Need to track which processed from last time?
# Process only kind 3 events for explicit following
results = conn.exec('SELECT * FROM events WHERE kind = 3 AND delete_event_id IS NULL')

results.each do |row|

  # Technically the identity will already exist if we ran this after import_events.rb
  follower_id = create_identity(conn, row['pubkey'])

  # TODO: better JSON parse error handling
  json_event = JSON.parse(row["event_json"])

  # Process all P tags and create relationship
  for tag in get_event_p_tags(json_event)

    ref_identity = create_identity(conn, tag[1])

    add_follow_relationship(conn, follower_id["id"], ref_identity["id"], row["id"], 'explicit')
  end
end
