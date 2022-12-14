require 'json'
require_relative './lib'

conn = get_db_connection

results = conn.exec("select t.key, t.value
from tags t
WHERE
t.key = 'e' and
NOT EXISTS (
   SELECT
   FROM   events e
   WHERE  e.event_id = t.value
)
group by t.value, t.key")

results.each do |row|
  # Validate tag e value length / chars - [a-z0-9]{64}

  # TODO: Query Nostr for event ids to attempt to find the missing events
  p row['value']
end
