# PLANTies

This is a little, distributed Elixir program for monitoring and commanding
Raspberry PI. I wrote it for monitoring my plants, hence the name.

# Use

You need to start one instance of the project on the RPI, like this:

    MIX_ENV=pi iex --cookie <cookie_string> --sname planties -S mix

and on any other system within the network:

    MIX_ENV=pi iex --cookie <cookie_string> --sname planties -S mix

You can verify it works by writing:

    LED.blink_many 10

in either console.
