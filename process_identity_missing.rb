require 'json'
require_relative './lib'

conn = get_db_connection

results = conn.exec("select t.key, t.value
from tags t
WHERE
t.key = 'p' and
NOT EXISTS (
   SELECT
   FROM   identities i
   WHERE  i.pubkey = t.value
)
group by t.value, t.key")

# NOTE: Requires the tags table populated
results.each do |row|
  # Validate tag p value length / chars - [a-z0-9]{64}

  # TODO: Query Nostr for event author to attempt to find their missing events
  p row['value']
end
