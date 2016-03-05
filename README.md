# ExfileB2

[![Build Status](https://travis-ci.org/keichan34/exfile-b2.svg?branch=master)](https://travis-ci.org/keichan34/exfile-b2)

A [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) adapter for [Exfile](https://github.com/keichan34/exfile).

The B2 client is currently built in to this package. There are plans to break it out as its own
package in the near future. Stay tuned.

Requires Elixir ~> 1.2.

## Installation

  1. Add exfile_b2 to your list of dependencies in `mix.exs`:

        def deps do
          [
            {:exfile, ">= 0.1.1"},
            {:exfile_b2, "~> 0.1.1"}
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
            "store" => [ExfileB2.Backend, %{
              hasher: Exfile.Hasher.Random,
              account_id: "the Account ID to your B2 account",
              application_key: "the Application Key to your B2 account",
              bucket: "name of the bucket to store files"
            }]
          }
