require 'json'
require_relative './lib'

conn = get_db_connection

# TODO: What to do with event + tags when an event is deleted? cleanup tags? Ignore?
# TODO: Add support for chained p-tags e.g. { tags: ["p": ["p1", "p2", "p3"]]} (NIP-10)

results = conn.exec('SELECT * FROM events WHERE delete_event_id IS NULL')

results.each do |row|

  tags = JSON.parse(row['event_json'])['tags']
  tags.each do |tag|

    clean_tag = tag[0] || ''

    # Tags to ignore
    skip_tags = [nil, '', 'nonce']
    if skip_tags.include?(clean_tag.strip)
      next
    end

    # Instead of setting an empty string tag value, set NULL
    if tag[1] == ''
      tag[1] = nil
    end

    # Handle e-tag markers
    # TODO: Handle index errors?
    # TODO: validate e value is [a-z0-9]{64} (or next)
    if tag[0] == 'e' and tag[3] == 'root' and tag.length() == 4
      # TODO: Create event tag with marker of root AND tag["2"] as relay hint
    elsif tag[0] == 'e' and tag[3] == 'reply' and tag.length() == 4
      # TODO: Create event tag with marker of reply AND tag["2"] as relay hint
    else
      # Normal event tag
    end

    # Handle p-tags
    # TODO: validate p value is [a-z0-9]{64} (or next)
    # get_p_tag_pubkeys(get_event_p_tags(json_event)) # Insert a p tag for each

    # TODO: What about other deeper tag values (past index 1). How to store?
    select_tag = create_tag(conn, tag[0], tag[1])

    if !select_tag.nil?
      create_event_tag(conn, row['id'], select_tag["id"])
    else
      puts "Error with tag: " + (tag[0] || '') + ' :: ' + (tag[1] || '')
    end
  end
end
