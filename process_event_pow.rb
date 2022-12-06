require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

results = conn.exec('select * from events')

results.each do |row|

  pow = get_pow(row["event_id"])
  update_event_pow(conn, row["event_id"], pow)

end
