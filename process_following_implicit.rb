require 'json'
require_relative './lib'

conn = get_db_connection()


results = conn.exec("SELECT * FROM events WHERE (kind = 1 OR (kind = 7 and (content = '' or content = '+'))) AND delete_event_id IS NULL")

results.each do |row|

  # Technically the identity will already exist if we ran this after import_events.rb
  follower_id = create_identity(conn, row['pubkey'])

  # TODO: better JSON parse error handling
  json_event = JSON.parse(row["event_json"])

  # Process all p-tags and create relationship
  for tag in get_event_p_tags(json_event)

    ref_identity = create_identity(conn, tag[1])

    add_follow_relationship(conn, follower_id["id"], ref_identity["id"], nil, 'implicit')
  end

  # Process all e-tags and create relationship
  for tag in get_event_e_tags(json_event)

    # Need to lookup event pubkey to get the ref_identity
    ref_event = get_event(conn, tag[1])
    next if !ref_event
    ref_identity = create_identity(conn, ref_event["pubkey"])

    add_follow_relationship(conn, follower_id["id"], ref_identity["id"], nil, 'implicit')
  end
end
