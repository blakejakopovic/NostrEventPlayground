require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

results = conn.exec('SELECT * from identities')

results.each do |row|

  results2 = conn.exec_params("select count(*) from (select date_trunc('day', created_at) as dt, count(1)
from events e
where pubkey = $1
and created_at > current_date - interval '1 year'
group by 1) as days_active", [row["pubkey"]]).first

  update_identity_with_year_days_active(conn, row["pubkey"], results2["count"])

end
