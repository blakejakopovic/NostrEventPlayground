require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

results = conn.exec('SELECT * FROM events')

results.each do |row|

  tags = JSON.parse(row['event_json'])['tags'][0]
  # TODO: Fix this to make it a .each loop, as e tag MAY not be first
  if !tags.nil? then
    if !tags[1].nil? then
      if tags[0] == 'e' || tags[0] == '#e' then
        parent_event = get_event(conn, tags[1])
        if !parent_event.nil?
          # Set this as the parent_id for the current row
          update_event_with_parent(conn, row["event_id"], parent_event["id"])

        end
      end
    end
  end
end
