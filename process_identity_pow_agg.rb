require_relative './lib'

conn = get_db_connection

results = conn.exec('select * from identities')

results.each do |row|

  # Start with the identity pubkey PoW (fallback to zero)
  pow_agg = Integer(row["pow"]) || 0

  identity_id = row["id"]

  # Fetch all events created by the identity and sum event pow
  events = conn.exec('select SUM(pow) as pow_agg from events where identity_id = $1', [identity_id]).first

  pow_agg += Integer(events["pow_agg"])

  update_identity_pow_agg(conn, identity_id, pow_agg)
end
