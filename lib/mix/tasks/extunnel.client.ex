defmodule Mix.Tasks.Extunnel.Client do
  use Mix.Task

  def run(_) do
    Extunnel.start_client
    Mix.Tasks.Run.run run_args()
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
