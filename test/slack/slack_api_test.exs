defmodule Slack.SlackAPITest do
  use ExUnit.Case, async: true

  describe "parse_channels/1" do
    test "Channel capture" do
      text = "<@UMAFQ97F1> <#CM8KWJ1L5|delega><#CMAQ7M3HU|general> do some awesome things"

      assert Slack.API.parse_channels(text) == ["CM8KWJ1L5", "CMAQ7M3HU"]
    end

    test "Channel spoofing" do
      text = "<@UMAFQ97F1> &lt;#CM8KWJ1L5|delega&gt; do stuff"

      assert Slack.API.parse_channels(text) == []
    end
  end

  test "User capture" do
    text = "hello <@UMAFQ97F1> there <@UMAFQ97F1|kyle> how are you?"

    assert Slack.API.parse_users(text) == ["UMAFQ97F1", "UMAFQ97F1"]
  end

  describe "trim_channels/1" do
    test "Multiple channels with whitespace and without whitspace" do
      text =
        "  <#CM8KWJ1L5|delega>  <#CMAQ7M3HU|general><#CMAQ7M3HU|general> do some awesome things <#CMAQ7M3HU|general> "

      assert Slack.API.trim_channels(text) == "do some awesome things <#CMAQ7M3HU|general> "
    end
  end
end
