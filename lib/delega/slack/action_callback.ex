defmodule Delega.Slack.ActionCallback do
  @derive [
    {Jason.Encoder, only: [:function, :args]},
    {Msgpax.Packer, fields: [:function, :args]}
  ]
  defstruct [:function, :args]

  @type t :: %__MODULE__{
          function: String.t(),
          args: [any]
        }

  def encode(callback) when is_nil(callback) do
    nil
  end

  def encode(callback) do
    [Atom.to_string(callback.function), callback.args]
  end

  def decode(data) when is_nil(data) do
    nil
  end

  def decode(data) do
    [function, args] = data

    %Delega.Slack.ActionCallback{
      function: String.to_atom(function),
      args: args
    }
  end

  def execute(callback) when is_nil(callback) do
    []
  end

  def execute(callback) do
    apply(Delega.Slack.Commands, callback.function, callback.args)
  end
end
