require 'json'
require_relative './lib'

conn = get_db_connection

results = conn.exec('SELECT * FROM events WHERE delete_event_id IS NULL ORDER BY created_at')

# TODO: We can simplify this down to a single update query
# TODO: Review against general process_event_tags script and maybe merge?
results.each do |row|

  json_event = JSON.parse(row["event_json"])

  for tag in get_event_e_tags(json_event)

    ref_event = get_event(conn, tag[1])

    if ref_event

      # TODO: Update this to support the new events_tags marker column
      # Backward support before reply/root hints exists
      if tag[3] == 'reply' or tag[3].nil?
        update_event_with_parent_event(conn, row["id"], ref_event["id"])

      # Only set root event if the root event doens't have a parent
      # TODO: This isn't perfect as distributed data.. need a DB constraint
      elsif tag[3] == 'root' and ref_event["parent_event_id"].nil?
        update_event_with_root_event(conn, row["id"], ref_event["id"])
      end
    end

  end
end
