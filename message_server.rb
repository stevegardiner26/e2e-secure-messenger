require 'socket'

class Server
  def initialize(address, port)
    @server = TCPServer.open(port, address)

    @connection = Hash.new
    @clients_connected = Hash.new

    @connection[:server] = @server
    @connection[:clients] = @clients_connected

    puts "Starting server on port #{port}..."
    run

  end

  def run
    loop{
      client_connection = @server.accept
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

      if @connection[:clients][username] != nil # double checking avoiding connection if user exits
         conn.puts "This username already exist"
         conn.puts "quit"
         conn.kill self
      end

      puts "Connection established #{username} => #{conn}"
      @connection[:clients][username] = conn
      conn.puts "Connection established successfully #{username} => #{conn}, you may continue with chatting....."

      start_chatting(username, conn) # allow chatting
      end
    }.join
  end

  def start_chatting(username, connection)
    loop do
      message = connection.gets.chomp
      puts @connection[:clients]
      (@connection[:clients]).keys.each do |client|
        @connection[:clients][client].puts "#{username} : #{message}"
      end
    end
  end
end


Server.new( 2000, "localhost" )