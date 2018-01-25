require 'socket'
require 'thread'

class SocketService

  attr_reader :closed

  def initialize
    @server = nil
    @group = ThreadGroup.new
    @service_thread = nil
  end

  def serve(port, &action)
    @closed = false
    @action = action
    @server = TCPServer.new 9999
    @service_thread = service_task
    @group.add(@service_thread)
  end

  def pending_sessions
    @group.list.size - (!@service_thread.nil? ? 1 : 0)
  end

  def service_task
    loop do
      Thread.start(@server.accept) do |client|
        server_task(client)
      end
    end
  end

  def server_task(client)
    @action.call(client)
    client.close
  end

  def close
    @service_thread.kill
    @service_thread = nil
    @server.close
    wait_for_servers
    @closed = true
  end

  def wait_for_servers
    @group.list(&:join)
  end
end
