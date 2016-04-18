defmodule ExfileB2.LocalCacheTest do
  use ExUnit.Case, async: false

  alias ExfileB2.LocalCache

  test "store/2 makes a new file and stores iodata" do
    {:ok, path} = LocalCache.store("stores-iodata", ["hello"])

    assert File.exists?(path) == true
    assert {:ok, "hello"} = File.read(path)
  end

  test "store/2 using an old key removes the previous file" do
    {:ok, path1} = LocalCache.store("old-key", ["hello"])
    {:ok, path2} = LocalCache.store("old-key", ["hello"])

    assert File.exists?(path1) == false
    assert File.exists?(path2) == true
  end

  test "fetch/1 returns the path of a stored file" do
    {:ok, path} = LocalCache.store("stored-file", ["hello"])

    assert {:ok, ^path} = LocalCache.fetch("stored-file")
  end

  test "delete/1 deletes the file and key of one file" do
    {:ok, path1} = LocalCache.store("delete-1", ["hello"])
    {:ok, path2} = LocalCache.store("delete-2", ["hello"])

    LocalCache.delete("delete-1")

    assert File.exists?(path1) == false
    assert :error = LocalCache.fetch("delete-1")
    assert File.exists?(path2) == true
    assert {:ok, ^path2} = LocalCache.fetch("delete-2")
  end

  test "flush/0 deletes all files in the cache" do
    {:ok, path1} = LocalCache.store("flush-1", ["hello"])
    {:ok, path2} = LocalCache.store("flush-2", ["hello"])

    LocalCache.flush

    assert File.exists?(path1) == false
    assert :error = LocalCache.fetch("delete-1")
    assert File.exists?(path2) == false
    assert :error = LocalCache.fetch("delete-2")
  end

  test "cache deletes files if it is terminated" do
    {:ok, path1} = LocalCache.store("flush-1", ["hello"])
    {:ok, path2} = LocalCache.store("flush-2", ["hello"])

    Process.exit(:erlang.whereis(LocalCache), :shutdown)

    :timer.sleep(500)

    assert File.exists?(path1) == false
    assert :error = LocalCache.fetch("delete-1")
    assert File.exists?(path2) == false
    assert :error = LocalCache.fetch("delete-2")
  end

  test "LRU algorithm evicts stored files that least recently used when exceeding the storage quota" do
    LocalCache.flush

    Application.put_env(:exfile_b2, :local_cache_size, 10)

    {:ok, path1} = LocalCache.store("lru-1", ["hello1"])
    {:ok, path2} = LocalCache.store("lru-2", ["hello2"])

    LocalCache.vacuum

    assert File.exists?(path1) == false
    assert :error = LocalCache.fetch("lru-1")
    assert File.exists?(path2) == true
    assert {:ok, ^path2} = LocalCache.fetch("lru-2")

    Application.put_env(:exfile_b2, :local_cache_size, 100_000_000)
  end
end
