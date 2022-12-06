require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

# TODO: Process unfollows or deleted follow events? Need to track which processed from last time?
# TODO: Insert pubkeys from p tags too

results = conn.exec('SELECT * FROM events WHERE kind = 3 AND delete_event_id IS NULL')

results.each do |row|

  follower_id = get_identity(conn, row["pubkey"])["id"]

  tags = JSON.parse(row['event_json'])['tags']
  if !tags.nil? then


    tags.each do |tag|
      # Check it's a p (public key) tag
      if tag[0] == 'p'

        # TODO: Better error checking if value even exists
        followee = get_identity(conn, tag[1])

        # TODO: Better error checking lookups were successful
        if follower_id != nil and followee != nil
          followee_id = followee["id"]

          add_follow_relationship(conn, follower_id, followee_id, row["id"])
        end
      end
    end
  end
end
