# ExfileB2

[![Build Status](https://travis-ci.org/keichan34/exfile-b2.svg?branch=master)](https://travis-ci.org/keichan34/exfile-b2)

A [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) adapter for [Exfile](https://github.com/keichan34/exfile).

ExfileB2 uses a local file-based cache to speed up file accesses and reduce bandwidth
needs especially when doing processing. The default maximum is 100 MB, you can
configure this to any amount you need.

ExfileB2 uses [B2Client](https://github.com/keichan34/b2_client) to interface
with Backblaze B2. If you want to use with Backblaze B2 without Exfile, you can
use that library.

Requires Elixir ~> 1.2.

## Installation

  1. Add exfile_b2 to your list of dependencies in `mix.exs`:

        def deps do
          [
            {:exfile, "~> 0.3.1"},
            {:exfile_b2, "~> 0.2.2"}
          ]
        end

  2. Ensure exfile_b2 is started before your application:

        def application do
          [
            applications: [
              :exfile,
              :exfile_b2
            ]
          ]
        end

  3. Configure the backend in `config.exs` (or environment equivalent)

        config :exfile, Exfile,
          backends: %{
            "store" => {ExfileB2.Backend,
              hasher: Exfile.Hasher.Random,
              account_id: "the Account ID to your B2 account",
              application_key: "the Application Key to your B2 account",
              bucket: "name of the bucket to store files"
            }
          }

  4. Configure ExfileB2's local cache maximum size (optional, default 100 MB)

        config :exfile_b2, :local_cache_size, 100_000_000 # bytes
