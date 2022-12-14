require_relative './lib'

conn = get_db_connection

# NOTE: !!! THIS SCRIPT IS VERY SLOW (2hrs) !!!

# Query for all parent events (have at least one child)
# Note: This is dependant on processing_identity_pow_agg first
# Perhaps filter down to kind=1 or kind=42
# TODO: How do we bottom up calculate this with caching
results = conn.exec('select * from events where parent_event_id is null')

results.each do |row|

  pow_agg = 0
  descendant_count = 0

  # puts "event_id: #{row["event_id"]}"

  # Recursively lookup all children evens for parent event
  results2 = conn.exec_params('
WITH RECURSIVE
    -- starting node(s)
    starting (id, parent_event_id, pubkey, pow) AS
    (
      SELECT e.id, e.parent_event_id, e.pubkey, e.pow
      FROM events AS e
      WHERE e.id = $1
    ),
    descendants (id, parent_event_id, pubkey, pow) AS
    (
      SELECT e.id, e.parent_event_id, e.pubkey, e.pow
      FROM starting AS e
      UNION ALL
      SELECT e.id, e.parent_event_id, e.pubkey, e.pow
      FROM events AS e JOIN descendants AS d ON e.parent_event_id = d.id
    ),
    ancestors (id, parent_event_id, pubkey, pow) AS
    (
      SELECT e.id, e.parent_event_id, e.pubkey, e.pow
      FROM events AS e
      WHERE e.id IN (SELECT parent_event_id FROM starting)
      UNION ALL
      SELECT e.id, e.parent_event_id, e.pubkey, e.pow
      FROM events AS e JOIN ancestors AS a ON e.id = a.parent_event_id
    )
TABLE ancestors
UNION ALL
TABLE descendants
Order by parent_event_id desc', [row["id"]])

  results2.each do |row2|

    identity = get_identity(conn, row2["pubkey"])
    identity_pow_agg = identity["pow_agg"]

    # puts "event_pow: #{event_pow}"
    # puts "identity_pow_agg: #{identity_pow_agg}"

    pow_agg += Integer(row2["pow"])
    # TODO: Unsure why Integer/to_i is needed as I get "String can't be coerced into Integer"
    pow_agg += Integer(identity_pow_agg)

    descendant_count += 1

  end

  # puts "EVENT: pow_agg: #{pow_agg}"
  # puts "----"

  update_event_pow_agg(conn, row["id"], pow_agg, descendant_count)
end
