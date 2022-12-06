require 'pg'
require 'json'
require_relative './lib'

conn = PG.connect(
        :dbname => 'nostr',
        :user => 'postgres',
        :port => 5432,
        :host => 'localhost'
        )


# TODO: Add validation here to ensure it's a valid pubkey

# Find all unique pubkey from events to pre-seed the identity table
results = conn.exec('SELECT DISTINCT on (pubkey) pubkey FROM events')
results.each do |row|
  conn.exec_params("INSERT INTO public.identities (pubkey) VALUES ($1) ON CONFLICT DO NOTHING;", [row['pubkey']])
end

# TODO: Insert pubkeys from event p tags too
# get_event_p_tags(event)
