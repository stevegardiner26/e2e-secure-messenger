require 'socket'

class Client
  def initialize(socket)
    @socket = socket
    @request = send_request
    @response = listen_response

    @request.join # will send the request to server
    @response.join # will receive response from server
  end

  def send_request
    puts "Please choose to login or register (Type 'login' or 'register'):"
    begin
      Thread.new do
        loop do
          message = $stdin.gets.chomp
          @socket.puts message
        end
      end
    rescue IOError => e
      puts e.message
      # e.backtrace
      @socket.close
    end

  end

  def listen_response
    begin
      Thread.new do
        loop do
          response = @socket.gets.chomp
          puts "#{response}"
          if response.eql?'quit'
            @socket.close
          end
        end
      end
    rescue IOError => e
      puts e.message
      # e.backtrace
      @socket.close
    end
  end
end



socket = TCPSocket.open( "localhost", 2000 )
Client.new( socket )