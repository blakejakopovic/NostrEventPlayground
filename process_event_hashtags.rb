require 'json'
require_relative './lib'

conn = get_db_connection()

results = conn.exec("select *
from events e
where
(kind = 1 or kind = 42) and
content ~ '#[[:alnum:]]+'")

results.each do |row|
  row["content"].scan(/#[[:alnum:]]+/) { |match|

    hashtag = create_hashtag(conn, match)
    create_event_hashtag(conn, row["id"], hashtag["id"]) if hashtag
  }
end
