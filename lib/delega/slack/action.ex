defmodule Delega.Slack.Action do
  alias Delega.Slack.ActionCallback

  @derive {Jason.Encoder, only: [:todo_id, :action, :callback]}

  defstruct [:todo_id, :action, :callback]

  @type t :: %__MODULE__{
          todo_id: integer,
          action: String.t(),
          callback: ActionCallback.t()
        }
end
