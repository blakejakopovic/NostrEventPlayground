require 'json'
require_relative './lib'

conn = get_db_connection()

file = File.read('./events.json')
data_hash = JSON.parse(file)

# [
#     {
#         "id": "b2e03951843b191b5d9d1969f48db0156b83cc7dbd841f543f109362e24c4a9c",
#         "pubkey": "32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245",
#         "created_at": 1650050002,
#         "kind": 1,
#         "tags": [],
#         "content": "hello, this is my new key",
#         "sig": "4342eff1d78a82b42522cd26ec66a5293eca997f81d4b80efd02230d3d27317fb63d42656e8f32383562f075a2b6d999b60dcf70e2df18cf5e8b3801faeb0bd6"
#     },
# ]

data_hash.each do |event|

  # TODO: Validate event data is value (required keys/values, data lengths, etc)
  # TODO: Validate event id and event sig fields

  identity = create_identity(conn, event["pubkey"])

  create_event(
    conn,
    event["id"],
    event["pubkey"],
    Time.at(event["created_at"]),
    event["kind"],
    event["content"],
    event["sig"],
    event.to_json,
    identity["id"]
  )

end
