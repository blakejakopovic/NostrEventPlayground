require 'json'
require_relative './lib'

conn = get_db_connection

# NIP-01 - Basic protocol flow description
# Kind 0 is set_metadata
# {name: <username>, about: <string>, picture: <url, string>}
# We need to ignore deleted, only process latest using created_at as timestamp

results = conn.exec('SELECT DISTINCT on (pubkey) pubkey,* FROM events WHERE kind = 0 AND delete_event_id IS NULL ORDER BY pubkey, created_at desc')

results.each do |row|

  begin
    event_json = JSON.parse(row['event_json'])
    if event_json
      meta_data_json = JSON.parse(event_json['content'])

      name = meta_data_json['name'].strip || nil
      about = meta_data_json['about'].strip || nil
      picture = meta_data_json['picture'].strip || nil

      # TODO: Should be all upper or lower case
      lud06 = meta_data_json['lud06'].strip || nil

      update_identity_with_metadata(conn, row["pubkey"], name, about, picture, lud06, row["id"])
    end
  rescue StandardError => e
    # Usually invalid JSON in content
    # puts "Error!! #{e}" + row['event_json'] # Some unexpected tokens in the JSON data
    next
  end
end
