defmodule Delega.RemindersTest do
  use ExUnit.Case, async: true

  import Delega.Reminders

  describe "Calculate reminder times" do
    test "ms_until_reminder/1 23:45:00" do
      {:ok, now} = Time.new(23, 45, 0)
      ms = ms_until_reminder(now)

      assert ms == 15 * 60 * 1000
    end

    test "ms_until_reminder/1 00:32:00" do
      {:ok, now} = Time.new(0, 32, 0)
      ms = ms_until_reminder(now)

      assert ms == 28 * 60 * 1000
    end
  end
end
