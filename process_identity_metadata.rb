require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )



# NIP-01 - Basic protocol flow description
# Kind 0 is set_metadata
# {name: <username>, about: <string>, picture: <url, string>}
# We need to ignore deleted, only process latest using created_at as timestamp
# NOTE: Postgres specific query

# NOTE: Depends on process_identity_preseed.rb

results = conn.exec('SELECT DISTINCT on (pubkey) pubkey,* FROM events WHERE kind = 0 AND delete_event_id IS NULL ORDER BY pubkey, created_at desc')

results.each do |row|

  begin
    event_json = JSON.parse(row['event_json'])
    if event_json
      meta_data_json = JSON.parse(event_json['content'])

      name = meta_data_json['name'] || ''
      about = meta_data_json['about'] || ''
      picture = meta_data_json['picture'] || ''
      recommend_server = meta_data_json['recommend_server'] || ''

      update_identity_with_metadata(conn, row["pubkey"], name, about, picture, recommend_server, row["id"])
    end
  rescue
    # puts "Error!! " + row['event_json'] # Some unexpected tokens in the JSON data
    next
  end
end
