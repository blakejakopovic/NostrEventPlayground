require_relative './lib'

conn = get_db_connection

results = conn.exec('select * from identities')
results.each do |row|

    pow = get_pow(row["pubkey"])

    update_identity_pow(conn, row["id"], pow)
end
