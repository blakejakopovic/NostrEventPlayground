#export PATH="/usr/local/opt/ruby/bin:$PATH"

require 'pg'
require 'json'

file = File.read('./events.json')

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )


data_hash = JSON.parse(file)

# [
#     {
#         "id": "b2e03951843b191b5d9d1969f48db0156b83cc7dbd841f543f109362e24c4a9c",
#         "pubkey": "32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245",
#         "created_at": 1650050002,
#         "kind": 1,
#         "tags":
#         [],
#         "content": "hello, this is my new key",
#         "sig": "4342eff1d78a82b42522cd26ec66a5293eca997f81d4b80efd02230d3d27317fb63d42656e8f32383562f075a2b6d999b60dcf70e2df18cf5e8b3801faeb0bd6"
#     },
# ]

# print data_hash[0].to_json

data_hash.each do |event|
  conn.exec_params(
      "INSERT INTO events (event_id, pubkey, created_at, kind, content, sig, event_json)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT DO NOTHING;",
      [
        event["id"],
        event["pubkey"],
        Time.at(event["created_at"]),
        event["kind"],
        event["content"],
        event["sig"],
        event.to_json,
      ])


    # TODO: Set first_seen to now
    # TODO: Set sig_verified as bool
    # TODO: Set id_verified as bool

    # Set is_reply=true if e tag
    # Create Identity entry with pubkey
    # if kind=0, update Identity table
    # if kind=2, update Identity table with recommended servers
    # if kind=3, populate identity_follow table (pubkeyA follows pubkeyB)
    # if kind=5, Insert event and update parent with hidden_event with event_id REF

    # How to handle replies (e tags) - create M2M table
    # How to handle mentions (p tags) - create M2M table

end
