defmodule DelegaWeb.SecondsToStringTest do
  use DelegaWeb.ConnCase

  import DelegaWeb.SlashController

  test "3 days ago" do
    assert seconds_to_string(60 * 60 * 24 * 3 + 60 * 60 * 7) == "3 days ago"
  end

  test "1 day ago" do
    assert seconds_to_string(60 * 60 * 24) == "1 day ago"
  end

  test "4 hours ago" do
    assert seconds_to_string(60*60*4 + 60*23) == "4 hours ago"
  end

  test "1 hour ago" do
    assert seconds_to_string(60*60) == "1 hour ago"
  end

  test "20 minutes ago" do
    assert seconds_to_string(60*20) == "20 minutes ago"
  end

  test "just now" do
    assert seconds_to_string(60*5) == "just now"
  end
end
