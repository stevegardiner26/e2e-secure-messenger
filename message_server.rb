require 'socket'

class Server
  def initialize(socket_address, socket_port)
    @server_socket = TCPServer.open(socket_port, socket_address)

    @connections_details = Hash.new
    @connected_clients = Hash.new

    @connections_details[:server] = @server_socket
    @connections_details[:clients] = @connected_clients

    puts 'Started server.........'
    run

  end

  def run
    loop{
      client_connection = @server_socket.accept
      Thread.start(client_connection) do |conn| # open thread for each accepted connection
      conn_type = conn.gets.chomp
      username = ""
      conn.puts "Starting #{conn_type} process..."
      if conn_type == 'register'
        conn.puts "Please Enter a Username:"
        username = conn.gets.chomp
        conn.puts "Please Enter a Password:"
        password = conn.gets.chomp
        # TODO: Salt Password and enter this data into mysql database
      elsif conn_type == 'login'
        conn.puts "Please Enter your Username: "
        username = conn.gets.chomp
        conn.puts "Please Enter your Password:"
        password = conn.gets.chomp
        # TODO: Salt Password and check this data against the mysql database
      else
        conn.puts "Neither option was selected! Disconnecting!"
        conn.kill self
      end

      if(@connections_details[:clients][username] != nil) # double checking avoiding connection if user exits
         conn.puts "This username already exist"
         conn.puts "quit"
         conn.kill self
      end

      puts "Connection established #{username} => #{conn}"
      @connections_details[:clients][username] = conn
      conn.puts "Connection established successfully #{username} => #{conn}, you may continue with chatting....."

      establish_chatting(username, conn) # allow chatting
      end
    }.join
  end

  def establish_chatting(username, connection)
    loop do
      message = connection.gets.chomp
      puts @connections_details[:clients]
      (@connections_details[:clients]).keys.each do |client|
        @connections_details[:clients][client].puts "#{username} : #{message}"
      end
    end
  end
end


Server.new( 2000, "localhost" )