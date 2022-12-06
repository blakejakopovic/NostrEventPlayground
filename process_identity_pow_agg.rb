require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )


# TODO: Maybe add in their own identity PoW into their sum agg events PoW
results = conn.exec('select * from identities')

results.each do |row|

  pow_agg = 0
  pubkey = row["pubkey"]

  results2 = conn.exec('select * from events where pubkey=$1', [pubkey])

  results2.each do |result2|
    event_pow = get_pow(result2["event_id"])
    pow_agg += event_pow
  end

  update_identity_pow_agg(conn, row["id"], pow_agg)
end
