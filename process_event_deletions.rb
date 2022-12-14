require 'json'
require_relative './lib'

conn = get_db_connection


# NIP-09 - Event Deletion
# Kind 5 is deletion
# NOTE: We don't filter event_delete_id here, as NIP states you cannot delete a deletion
results = conn.exec('SELECT * FROM events WHERE kind = 5')

results.each do |row|

  json_event = JSON.parse(row["event_json"])

  # NIP-26 Delegated Event Signing support
  # delegation = get_event_delegation_tag(json_event)

  # We need to process all e tags in this event
  for tag in get_event_e_tags(json_event)

    target_event = get_event(conn, tag[1])
    if !target_event.nil?

      # TODO: Validate pubkey for both events match OR the delegation tag else it's invalid)
      # 1. source and target pubkey are the same
      # 2. source pubkey matches delegation pubkey
      # 3. source delegation pubkey matches target pubkey
      if row["pubkey"] = target_event["pubkey"] # or
         # row["pubkey"] = delegation[1] or
         # target_event["pubkey"] = delegation[1]
        update_event_with_deleted_event(conn, row["id"], target_event["id"])
      end
    end
  end
end
