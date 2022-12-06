require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )

# TODO: What to do with event + tags when an event is deleted? cleanup tags? Ignore?
results = conn.exec('SELECT * FROM events WHERE delete_event_id IS NULL')

results.each do |row|

  tags = JSON.parse(row['event_json'])['tags']
  tags.each do |tag|

    # Tags to ignore
    clean_tag = tag[0] || ''
    skip_tags = ['', 'nonce'] # 'e', '#e', 'p', '#p',
    if skip_tags.include?(clean_tag.strip)
      next
    end

    # TODO: What about other tag meta or values ["taga", "a", "b?", "c?"]
    create_tag(conn, tag[0], tag[1])

    # TODO: Make create_tag return id isntead of second look up
    select_tag = get_tag(conn, tag[0], tag[1])
    if !select_tag.first.nil?
      create_event_tag(conn, row['id'], select_tag.first["id"])
    else
      puts "Error with tag: " + (tag[0] || '') + ' :: ' + (tag[1] || '')
    end
  end
end
