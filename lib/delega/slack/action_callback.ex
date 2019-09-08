defmodule Delega.Slack.ActionCallback do
  @derive {Jason.Encoder, only: [:function, :args]}
  defstruct [:function, :args]

  @type t :: %__MODULE__{
          function: String.t(),
          args: [any]
        }
end
