require 'socket'
require 'mysql2'
require 'bcrypt'
require 'openssl'

class Server
  include BCrypt

  def initialize(address, port)
    # Initialize the TCP Server
    @server = TCPServer.open(address, port)

    # Initialize the connection and clients_connected variables as empty Hashes
    @connection = Hash.new
    @clients_connected = Hash.new

    # Populate the @connection variable with everything needed
    @connection[:server] = @server
    @connection[:clients] = @clients_connected

    # Initialize Database Connection
    @db = Mysql2::Client.new(host: 'localhost', username: 'messenger', password: 'dev', database: 'secure_messenger')

    # Create the users table if it doesn't exist already
    @db.query('CREATE TABLE IF NOT EXISTS users(name VARCHAR(255) PRIMARY KEY, password TEXT)ENGINE=INNODB;')

    @key = 'oLt7Dg2g51C8TMRXiR81Ue3k9G1P2kX8'

    # Start up the server to listen for clients
    puts "Starting server on port #{port}..."
    run

  end

  def send_data(conn, message)
    cipher = OpenSSL::Cipher.new('AES-256-CBC').encrypt
    cipher.key = (Digest::SHA1.hexdigest @key)[0..31]
    s = cipher.update(message) + cipher.final

    conn.puts s.unpack('H*')[0].upcase
  end

  def read_data(conn)
    response = conn.gets.chomp
    cipher = OpenSSL::Cipher.new('AES-256-CBC').decrypt
    cipher.key = (Digest::SHA1.hexdigest @key)[0..31]
    s = [response].pack("H*").unpack("C*").pack("c*")

    cipher.update(s) + cipher.final
  end

  def run
    # Start a loop to be listening for client connections endlessly
    loop{
      # Accept the client connection if it exists
      client_connection = @server.accept
      # Dedicate a thread to this specific accepted connection
      Thread.start(client_connection) do |conn|
        # Get the first message from the client which should be either 'register' or 'login'
        conn_type = read_data(conn)
        username = ""
        # Let the client know we are proceeding and what we are proceeding with
        send_data(conn,"Starting #{conn_type} process...")
        if conn_type == 'register'
          # If the client is registering we prompt them for a username and await an entry from the client
          send_data(conn, "Please Enter a Username:")
          username = read_data(conn)
          # After receiving an input for the username we prompt the client for a password and await an entry
          send_data(conn, "Please Enter a Password:")
          password = read_data(conn)
          # Use bcrypt to salt the password with a one way hash
          salted_pass = Password.create(password)
          # Insert the user and the salted password into the database
          res = @db.query("INSERT INTO users (name, password) VALUES ('#{username}', '#{salted_pass}')")
          # TODO: Handle this res error better
          if res
            # If an error returns we do not let the client proceed any farther
            send_data(conn, "Error Occurred (Most likely this username already exists)")
            send_data(conn, "quit")
            conn.close
          end
        elsif conn_type == 'login'
          # If the client is logging in we prompt them for their username and await their input
          send_data(conn, "Please Enter your Username: ")
          username = read_data(conn)
          # Search the database for a user with the same name as provided by the client
          db_user = @db.query("SELECT * FROM users WHERE name = '#{username}'")
          unless db_user.first
            # If we cannot find a user within the database we reject the client and close the connection
            send_data(conn, "Error Occurred (Most likely this username doesn't exists.)")
            send_data(conn, "quit")
            conn.close
          end
          # If we got to this point we assume the user exists because it does, and we prompt for a password
          # We then wait for the user to enter something for the password
          send_data(conn, "Please Enter your Password:")
          password = read_data(conn)
          # Fetch the password from the database entry and use bcrypt to make it comparable to the string entered
          # by the client
          unsalted_password = Password.new(db_user.first['password'])
          if unsalted_password != password
            # If the passwords do not match up then we prevent the user from accessing the server
            send_data(conn, "Password is Incorrect!")
            send_data(conn, "quit")
            conn.close
          end
        else
          # This will fire if neither 'register' or 'login' was entered on the clients initial connection
          send_data(conn, "Neither option was selected! Disconnecting!")
          send_data(conn, "quit")
          conn.close
        end

        if @connection[:clients][username] != nil
          # Double checking avoiding connection if user exists (Can't be logged in two places)
           send_data(conn, "This username already exist")
           send_data(conn, "quit")
           conn.close
        end

        # Logs to the server that the client successfully connected and passed auth
        puts "Connection established #{username} => #{conn}"
        # Add the current connection to the active clients list to keep track of them
        @connection[:clients][username] = conn
        # Let the user know that they have passed authentication
        send_data(conn, "Connection established successfully #{username} => #{conn}, you may continue with chatting (Type 'leave' to leave the chat).....")

        # List out the active users in the chat room for the current client connection
        user_list = []
        (@connection[:clients]).keys.each do |client|
          send_data(@connection[:clients][client], "#{username} has joined the chat.")
          user_list.push(client)
        end
        send_data(conn, "Active Users: #{user_list.join(", ")}")

        start_chatting(username, conn) # allow chatting
      end
    }.join
  end

  def start_chatting(username, connection)
    loop do
      # Fetch a message from the client
      message = connection.gets.chomp
      if message == "leave"
        # If the message is equal to 'leave' than the current connection is removed from the active clients list,
        # the rest of the clients are made aware that the user left and the connection is closed
        @connection[:clients].delete(username)
        (@connection[:clients]).keys.each do |client|
          send_data(@connection[:clients][client], "#{username} has left the chat.")
        end
        send_data(connection, "quit")
        connection.close
      end
      puts @connection[:clients]
      # Here is where we display the clients message to all other clients
      (@connection[:clients]).keys.each do |client|
        @connection[:clients][client].puts "#{message}"
      end
    end
  end
end

Server.new( "localhost", 2000)