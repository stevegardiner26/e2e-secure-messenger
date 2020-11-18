require 'socket'
require 'mysql2'
require 'bcrypt'

class Server
  include BCrypt

  def initialize(address, port)
    @server = TCPServer.open(address, port)

    @connection = Hash.new
    @clients_connected = Hash.new

    @connection[:server] = @server
    @connection[:clients] = @clients_connected

    @db = Mysql2::Client.new(host: 'localhost', username: 'messenger', password: 'dev', database: 'secure_messenger')
    @db.query('CREATE TABLE IF NOT EXISTS users(name VARCHAR(255) PRIMARY KEY, password TEXT)ENGINE=INNODB;')

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
        salted_pass = Password.create(password)
        res = @db.query("INSERT INTO users (name, password) VALUES ('#{username}', '#{salted_pass}')")
        # TODO: Handle this res error better
        if res
          conn.puts "Error Occurred (Most likely this username already exists)"
          conn.puts "quit"
          conn.close
        end
      elsif conn_type == 'login'
        conn.puts "Please Enter your Username: "
        username = conn.gets.chomp
        db_user = @db.query("SELECT * FROM users WHERE name = '#{username}'")
        unless db_user.first
          conn.puts "Error Occurred (Most likely this username doesn't exists.)"
          conn.puts "quit"
          conn.close
        end
        conn.puts "Please Enter your Password:"
        password = conn.gets.chomp
        unsalted_password = Password.new(db_user.first['password'])
        if unsalted_password != password
          conn.puts "Password is Incorrect!"
          conn.puts "quit"
          conn.close
        end
      else
        conn.puts "Neither option was selected! Disconnecting!"
        conn.puts "quit"
        conn.close
      end

      if @connection[:clients][username] != nil # double checking avoiding connection if user exists (Can't be logged in two places)
         conn.puts "This username already exist"
         conn.puts "quit"
         conn.close
      end

      puts "Connection established #{username} => #{conn}"
      @connection[:clients][username] = conn
      conn.puts "Connection established successfully #{username} => #{conn}, you may continue with chatting (Type 'leave' to leave the chat)....."

      user_list = []
      (@connection[:clients]).keys.each do |client|
        @connection[:clients][client].puts "#{username} has joined the chat."
        user_list.push(client)
      end
      conn.puts "Active Users: #{user_list.join(", ")}"

      start_chatting(username, conn) # allow chatting
      end
    }.join
  end

  def start_chatting(username, connection)
    loop do
      message = connection.gets.chomp
      if message == "leave"
        @connection[:clients].delete(username)
        (@connection[:clients]).keys.each do |client|
          @connection[:clients][client].puts "#{username} has left the chat."
        end
        connection.puts "quit"
        connection.close
      end
      puts @connection[:clients]
      (@connection[:clients]).keys.each do |client|
        @connection[:clients][client].puts "#{username}: #{message}"
      end
    end
  end
end


Server.new( "localhost", 2000)