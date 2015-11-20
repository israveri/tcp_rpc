# Erlang and OTP

This repository holds code written while reading the 'Erlang
and OTP' in Action book.

This application implements a RPC server with a TCP inteface.

## Running the server

* Clone the repository
* Compile the code

    $ erlc -o ebin src/*.erl

* Start Erlang shell adding compiled code to load path

    $ erl -pa ebin

* Start the application

    $ application:start(tcp_rpc).

* Start a simple tcp client to send messages to the server

    $ telnet localhost 1055
    io:fwrite("~p~n", ["Hello RCP server!"]).

