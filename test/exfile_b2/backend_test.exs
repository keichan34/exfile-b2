defmodule ExfileB2.BackendTest do
  use Exfile.BackendTest, {
    ExfileB2.Backend,
    account_id: "valid_account_id",
    application_key: "valid_application_key",
    bucket: "bucket"
  }
end
