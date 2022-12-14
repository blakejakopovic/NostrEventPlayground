require_relative './lib'

conn = get_db_connection

results = conn.exec('SELECT * from identities')

results.each do |row|

  days_active = conn.exec_params("select count(*) as days_active_count from (select date_trunc('day', created_at) as dt, count(1)
from events e
where identity_id = $1
and created_at > current_date - interval '1 year'
group by 1) as days_active_query", [row["id"]]).first

  update_identity_with_year_days_active(conn, row["pubkey"], days_active["days_active_count"])

end
