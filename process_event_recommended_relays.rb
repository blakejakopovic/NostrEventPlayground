require 'json'
require_relative './lib'

conn = get_db_connection

# TODO: We may want to process other event kinds here too
results = conn.exec('SELECT * FROM events WHERE kind = 1 AND delete_event_id IS NULL')

results.each do |row|

    json_event = JSON.parse(row["event_json"])

    # We map the relay to the event author pubkey
    for tag in get_event_e_tags(json_event)
      # TODO: Improve validation - Basic url validation
      # TODO: Filter loopback, localhost, 0.0.0.0, and private IP classes 192.168, 172, 169.
      relay_hint = tag[2] || ''

      if relay_hint.match(/wss?:\/\/.+/)
        relay = create_relay(conn, relay_hint.strip())

        # Lookup identity
        identity = get_identity(conn, row['pubkey'])
        if identity
          create_identity_relay(conn, identity["id"], relay["id"], 'etag')
        end
      end
    end

    # We map the relay to the p-tag pubkey
    for tag in get_event_p_tags(json_event)
      # TODO: Improve validation - Basic url validation
      # TODO: Filter loopback, localhost, 0.0.0.0, and private IP classes 192.168, 172, 169.
      relay_hint = tag[2] || ''

      if relay_hint.match(/wss?:\/\/.+/)
        relay = create_relay(conn, relay_hint.strip())

        # Lookup identity
        identity = get_identity(conn, tag[1])
        if identity
          create_identity_relay(conn, identity["id"], relay["id"], 'ptag')
        end
      end
    end
end
