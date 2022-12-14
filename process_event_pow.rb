require_relative './lib'

conn = get_db_connection

# Note: Let's not exclude any events atm, as even deletion/meta events contribute to pow_agg
results = conn.exec('SELECT * FROM events')

results.each do |row|

  pow = get_pow(row["event_id"])
  update_event_pow(conn, row["event_id"], pow)

end
