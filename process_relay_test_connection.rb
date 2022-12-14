require 'faye/websocket'
require 'eventmachine'
require_relative './lib'

conn = get_db_connection

results = conn.exec('SELECT * FROM relays')

results.each do |row|

  relay_uri = row["relay"]

  successful = false
  EM.run {
    # TODO: Hide errors from stdout like '4566078976:error:1416F086:SSL routines:tls_process_server_certificate:certificate verify failed:ssl/statem/statem_clnt.c:1921:'
    ws = Faye::WebSocket::Client.new(relay_uri)

    ws.on :open do |event|
      successful = true
      EventMachine.stop
    end

    ws.on :message do |event|
      successful = true
      EventMachine.stop
    end

    ws.on :close do |event|
      ws = nil
      EventMachine.stop
    end
  }

  if successful
    update_relay_last_connected(conn, row["id"])
  end
end
