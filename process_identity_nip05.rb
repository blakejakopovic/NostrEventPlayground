require 'uri'
require 'net/http'
require 'json'
require_relative './lib'

conn = get_db_connection

results = conn.exec('select DISTINCT on (pubkey) pubkey, content from events where kind = 0 and content like \'%"nip05":%\' AND delete_event_id IS NULL ORDER BY pubkey, created_at desc')

# TODO: Extend to support NIP-35 which allows servers to return relays as well
# {
#   "names": {
#     "bob": "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9"
#   },
#   "relays": {
#     "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9": [ "wss://relay.example.com", "wss://relay2.example.com" ]
#   },
# }

results.each do |row|

  # {"name":"snuffyDev","picture":"","nip05":"snuffydev@snuffyDev.ml"}
  x = JSON.parse(row["content"])
  y = x["nip05"]

  # Skip blanks
  next if y.nil? or y.strip == ''

  # Skip non-ascii
  next if y.force_encoding("UTF-8").ascii_only? == false

  # Validate email format
  next if !(y =~ URI::MailTo::EMAIL_REGEXP)

  a,b = y.split("@")
  next if a.nil? or a.strip == '' or b.nil? or b.strip == ''

  # Add sanity check here to ensure b is ONLY a domain and without a path
  b = b.split('/').first

  # TODO: Add some domain validation here to prevent weird HTTP requests
  # TODO: Filter out localhost, loopback, 0.0.0.0 and private ip classes
  url = "https://#{b}/.well-known/nostr.json?name=#{a}"
  uri = URI(url)
  begin
    res = Net::HTTP.get_response(uri)
    if !res.is_a?(Net::HTTPSuccess)
      next
    end

    json = JSON.parse(res.body)

    json_pubkey = json["names"][a]

    if json_pubkey == row["pubkey"]
      # NIP-05: Add handling for _@domain as a root identifier
      update_identity_nip05(conn, row["pubkey"], y.delete_prefix('_@'), DateTime.now())
    end

  rescue
    next # Bad JSON response
  end

end
