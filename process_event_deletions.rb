require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )


# NIP-09 - Event Deletion
# Kind 5 is deletion
# NOTE: We don't filter event_delete_id here, as NIP states you cannot delete a deletion
results = conn.exec('SELECT * FROM events WHERE kind = 5')

results.each do |row|

  tags = JSON.parse(row['event_json'])['tags'][0]
  if !tags.nil? then
    if !tags[1].nil? then
      if tags[0] == 'e' || tags[0] == '#e' then
        target_event = get_event(conn, tags[1])
        if !target_event.nil?

          # Need to validate pubkey for both events MATCH (or could be invalid delete)
          if target_event["pubkey"] = row["pubkey"]
            update_event_with_deleted_event(conn, row["id"], target_event["id"])
          end
        end
      end
    end
  end
end
