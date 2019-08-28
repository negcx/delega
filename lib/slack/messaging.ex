defmodule Slack.Messaging do
  def section(text) do
    %{
      "type" => "section",
      "text" => markdown(text)
    }
  end

  def option(text, value) do
    %{
      "text" => %{
        "type" => "plain_text",
        "text" => text
      },
      "value" => value
    }
  end

  def overflow(options) do
    %{
      "type" => "overflow",
      "options" => options
    }
  end

  def section(text, accessory) do
    %{
      "type" => "section",
      "text" => markdown(text),
      "accessory" => accessory
    }
  end

  def markdown(text) do
    %{
      "type" => "mrkdwn",
      "text" => text
    }
  end

  def button(%{text: text, value: value, style: style}) do
    style_str =
      case style do
        :primary -> "primary"
        :danger -> "danger"
        :default -> ""
      end

    %{
      "type" => "button",
      "text" => %{
        "type" => "plain_text",
        "text" => text
      },
      "value" => value,
      "style" => style_str
    }
  end

  def button(%{text: text, value: value}) do
    %{
      "type" => "button",
      "text" => %{
        "type" => "plain_text",
        "text" => text
      },
      "value" => value
    }
  end

  def actions(elements) do
    %{
      "type" => "actions",
      "elements" => elements
    }
  end

  def context(elements) do
    %{
      "type" => "context",
      "elements" => elements
    }
  end

  def accessory(element) do
    %{
      "accessory" => element
    }
  end

  def divider() do
    %{
      "type" => "divider"
    }
  end

  def ephemeral_response(blocks) do
    %{
      "response_type" => "ephemeral",
      "blocks" => blocks
    }
  end
end
