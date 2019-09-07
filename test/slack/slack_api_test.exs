defmodule Slack.SlackAPITest do
  use ExUnit.Case, async: true

  test "Channel capture" do
    text = "<@UMAFQ97F1> <#CM8KWJ1L5|delega><#CMAQ7M3HU|general> do some awesome things"

    assert Slack.API.parse_channels(text) == ["CM8KWJ1L5", "CMAQ7M3HU"]
  end

  test "Channel spoofing" do
    text = "<@UMAFQ97F1> &lt;#CM8KWJ1L5|delega&gt; do stuff"

    assert Slack.API.parse_channels(text) == []
  end

  test "User capture" do
    text = "hello <@UMAFQ97F1> there <@UMAFQ97F1|kyle> how are you?"

    assert Slack.API.parse_users(text) == ["UMAFQ97F1", "UMAFQ97F1"]
  end
end
