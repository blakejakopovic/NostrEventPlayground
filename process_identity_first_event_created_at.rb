require_relative './lib'

conn = get_db_connection

# TODO: Some data has 1970-01-01 01:00:00.000
# TODO: Consider validation or changing it to use events.first_event_created_at date
#       (when event was first seen, not the created_at data)
results = conn.exec('SELECT DISTINCT on (pubkey) pubkey, created_at FROM events order by pubkey, created_at asc')

results.each do |row|
  update_identity_with_first_event_created_at(conn, row['pubkey'], row['created_at'])
end
