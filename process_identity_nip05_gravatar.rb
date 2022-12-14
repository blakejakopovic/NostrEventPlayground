require 'gravatar-ultimate'
require 'xmlrpc'
require_relative './lib'

conn = get_db_connection

api = Gravatar.new(ENV["WORDPRESS_API_USER"], :api_key => ENV["WORDPRESS_API_KEY"])

# Only process identities with NIP05 that contain a complete email (not domain only)
results = conn.exec("select * FROM identities where nip05 IS NOT NULL AND nip05 like '%@%'")

results.each do |row|

  email = row['nip05']

  # Check if a gravatar exists for the email address
  if api.exists?(email)
    update_identity_gravatar(conn, row['pubkey'], true)
  end
end
