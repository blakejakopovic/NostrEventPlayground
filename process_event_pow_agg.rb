require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )


# NOTE: !!! THIS SCRIPT IS PRETTY SLOW !!!

# Query for all parent events (have at least one child)
# Note: This is dependant on processing_identity_pow_agg first
results = conn.exec('select * from events where parent_id in (select DISTINCT(parent_id) parent_id from events where parent_id is not null order by parent_id desc)')

results.each do |row|

  pow_agg = 0
  descendant_count = 0

  # puts "event_id: #{row["event_id"]}"

  # Recursively lookup all children evens for parent event
  results2 = conn.exec_params('
WITH RECURSIVE
    -- starting node(s)
    starting (id, parent_id) AS
    (
      SELECT e.id, e.parent_id, e.event_id, e.pubkey
      FROM events AS e
      WHERE e.id = $1
    ),
    descendants (id, parent_id) AS
    (
      SELECT e.id, e.parent_id, e.event_id, e.pubkey
      FROM starting AS e
      UNION ALL
      SELECT e.id, e.parent_id, e.event_id, e.pubkey
      FROM events AS e JOIN descendants AS d ON e.parent_id = d.id
    ),
    ancestors (id, parent_id) AS
    (
      SELECT e.id, e.parent_id, e.event_id, e.pubkey
      FROM events AS e
      WHERE e.id IN (SELECT parent_id FROM starting)
      UNION ALL
      SELECT e.id, e.parent_id, e.event_id, e.pubkey
      FROM events AS e JOIN ancestors AS a ON e.id = a.parent_id
    )
TABLE ancestors
UNION ALL
TABLE descendants
Order by parent_id', [row["id"]])

  results2.each do |row2|

    event_pow = get_pow(row2["event_id"])

    identity = get_identity(conn, row2["pubkey"])
    identity_pow_agg = identity["pow_agg"]

    # puts "event_pow: #{event_pow}"
    # puts "identity_pow_agg: #{identity_pow_agg}"

    pow_agg += event_pow
    # TODO: Unsure why to_i is needed as I get "String can't be coerced into Integer"
    pow_agg += identity_pow_agg.to_i

    descendant_count += 1

  end

  # puts "EVENT: pow_agg: #{pow_agg}"
  # puts "----"

  update_event_pow_agg(conn, row["id"], pow_agg, descendant_count)
end
