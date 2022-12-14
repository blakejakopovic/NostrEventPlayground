require_relative './lib'

conn = get_db_connection

results = conn.exec('SELECT DISTINCT on (pubkey) pubkey,content FROM events WHERE kind = 2 AND delete_event_id IS NULL ORDER BY pubkey, created_at desc')

results.each do |row|

      content = row['content']
      p content

      # TODO: Improve validation - Basic url validation
      # TODO: Filter loopback, localhost, 0.0.0.0, and private IP classes 192.168, 172, 169.
      if content.match(/wss:\/\/.*/)
        relay = create_relay(conn, content.strip())

        # Lookup identity
        identity = get_identity(conn, row['pubkey'])
        if identity
          create_identity_relay(conn, identity["id"], relay["id"], 'explicit')
        end
      end
end
