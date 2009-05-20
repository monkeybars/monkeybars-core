require "monkeybars/task_processor"

module Monkeybars
  class Debug
    extend Monkeybars::TaskProcessor

    # Reads in ARGV, and enables various Monkeybars specific debugging capabilities
    # TODO: Restore args not used
    def self.enable_on_debugging_args
      puts "inspecting args"
      puts ARGV
      argv = ARGV.dup
      until argv.empty?
        arg = argv.pop
        case arg
        when '--debug-server'
          port = ARGV.pop
          begin
            port.to_i
          rescue
            port = 4848
            # put the arg back
            argv.unshift port
          end
          start_server port
        when '--record-edt'
          puts "recording EDT"
          record_edt
        end
      end
    end

    def self.record_edt
      listener = lambda do |event|
                   puts "found event #{event}"
                 end
      Java::java::awt::Toolkit.default_toolkit.addAWTEventListener listener, 0xFFFFFFFFFFFF
    end
    # Use --debug-server to enable
    # allows user to telnet in and send code to be evaled. Results are returned.
    def self.start_server(port=4848)
      Thread.new do
        require 'socket'
        server = TCPServer.new(port)
        begin
          socket = server.accept_nonblock
        rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EINTR
          IO.select([server])
          retry
        end

        puts "connected!"
        until socket.closed?
          begin
          line = socket.readline
          puts "evaling #{line}"
          result = on_edt { eval line }
          puts "returning result #{result}"
          socket.write "#{result}\n"
          rescue => e
            puts "error, returning error #{e}"
            socket.write "#{e}\n"
          end
        end
      end
    end

    enable_on_debugging_args
  end
end