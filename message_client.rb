require 'socket'

class Client
  def initialize(socket)
    # Initialize the Client
    @socket = socket
    @request = send_request
    @response = listen_response

    @request.join # will send the request to server
    @response.join # will receive response from server
  end

  def send_request
    # Before executing a request, figure out what action to take
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
      @socket.close
    end

  end

  def listen_response
    begin
      Thread.new do
        loop do
          # Read any puts response's from the server
          response = @socket.gets.chomp
          # Display the responses to the end user
          puts "#{response}"
          # If the response is equal to quit we want to close the socket
          # (Use this as a command to cancel the client socket)
          if response.eql?'quit'
            @socket.close
          end
        end
      end
    rescue IOError => e
      puts e.message
      @socket.close
    end
  end
end



socket = TCPSocket.open( "localhost", 2000 )
Client.new( socket )