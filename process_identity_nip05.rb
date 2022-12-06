require 'uri'
require 'net/http'
require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

results = conn.exec('select DISTINCT on (pubkey) pubkey, content from events where kind = 0 and content like \'%"nip05":%\' AND delete_event_id IS NULL ORDER BY pubkey, created_at desc')

results.each do |row|

  # {"name":"snuffyDev","picture":"","nip05":"snuffydev@snuffyDev.ml"}
  x = JSON.parse(row["content"])
  y = x["nip05"]

  # Skip blanks
  next if y.nil? or y.strip == ''

  # Skip non-ascii
  next if y.force_encoding("UTF-8").ascii_only? == false

  a,b = y.split("@")
  next if a.nil? or a.strip == '' or b.nil? or b.strip == ''

  # Add sanity check here to ensure b is ONLY a domain, no URL path
  # b = b.split('/').first
  next if b.include?('/')

  # TODO: Add some domain validation here to prevent weird HTTP requests
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
      puts "Verified nip05: #{a} <#{y}> (#{json_pubkey})"

      # NIP-05: Add handling for _@domain as a root identifier
      update_identity_nip05(conn, row["pubkey"], y.delete_prefix('_@'), DateTime.now())
    end

  rescue
    next
  end

end
