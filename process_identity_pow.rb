require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

results = conn.exec('select * from identities')
results.each do |row|

    pow = get_pow(row["pubkey"])

    update_identity_pow(conn, row["id"], pow)
end
