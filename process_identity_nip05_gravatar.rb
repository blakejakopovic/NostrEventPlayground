require 'gravatar-ultimate'
require 'xmlrpc'
require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

api = Gravatar.new("", :api_key => "")

# identities with NIP05 that contain a complete email
results = conn.exec("select * FROM identities where nip05 IS NOT NULL AND nip05 like '%@%'")

results.each do |row|

  email = row['nip05']

  # Check if a gravatar exists for the email address
  if api.exists?(email)
    update_identity_gravatar(conn, row['pubkey'], true)
  end
end
