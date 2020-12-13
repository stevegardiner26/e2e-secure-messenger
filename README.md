# E2E Secure Messenger

An encrypted chat application, that uses sockets to message between clients and the server.

Ruby Version `>=2.6.0`

### Setup

Make sure to have a local instance of mysql running and to create a new table and create a new database user and give it the permissions to access:

    mysql>CREATE DATABASE secure_messenger; 
    mysql>USE secure_messenger;
    mysql>CREATE TABLE users(name VARCHAR(255) PRIMARY KEY, password TEXT);
    mysql>CREATE USER 'messenger'@'localhost' IDENTIFIED BY 'dev';
    mysql>GRANT ALL PRIVILEGES ON secure_messenger.users TO 'messenger'@'localhost';

After cloning the repository and cd into the repo make sure you have these gems installed:

    $ gem install socket
    $ gem install mysql2
    $ gem install bcrypt
    $ gem install openssl

In one terminal run the server file:

    $ ruby message_server.rb

In another terminal run the client file:

    $ ruby message_client.rb