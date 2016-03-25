#! /bin/bash

{{ locale }} ERLANG_HOME={{ otp_dir }} MIX_ENV={{mix_env}} iex --cookie {{ cookie }} --sname {{ sname }} -S mix
