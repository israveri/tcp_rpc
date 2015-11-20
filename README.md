# Erlang and OTP

This repository holds code written while reading the 'Erlang
and OTP' in Action book.

This application implements a RPC server with a TCP inteface.

## Running the server

1. Clone the repository
2. Compile the code

    $ erlc tr_server.erl

3. Start Erlang shell with `erl` and init the server

    $ tr_server:start_link(1055).

4. Start a simple tcp client to send messages to the server

    $ telnet localhost 1055
    io:fwrite("~p~n", ["Hello RCP server!"]).

