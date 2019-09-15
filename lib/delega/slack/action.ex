defmodule Delega.Slack.Action do
  alias Delega.Slack.ActionCallback

  @derive [
    {Jason.Encoder, only: [:todo_id, :action, :callback]},
    {Msgpax.Packer, fields: [:todo_id, :action, :callback]}
  ]

  defstruct [:todo_id, :action, :callback]

  @type t :: %__MODULE__{
          todo_id: integer,
          action: atom,
          callback: ActionCallback.t()
        }

  defp encode_action(action_atom) do
    case action_atom do
      :complete -> 1
      :reject -> 2
      :assign -> 3
    end
  end

  defp decode_action(action_id) do
    case action_id do
      1 -> :complete
      2 -> :reject
      3 -> :assign
    end
  end

  def encode(action) do
    [action.todo_id, encode_action(action.action), ActionCallback.encode(action.callback)]
  end

  def decode(data) do
    [todo_id, action_id, callback] = data
    callback = ActionCallback.decode(callback)
    action = decode_action(action_id)

    %Delega.Slack.Action{
      action: action,
      todo_id: todo_id,
      callback: callback
    }
  end

  def encode64(action) do
    action
    |> encode
    |> Msgpax.pack!(iodata: false)
    |> Base.encode64()
  end

  def decode64(data) do
    data
    |> Base.decode64!()
    |> Msgpax.unpack!()
    |> decode
  end
end
