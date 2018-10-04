defmodule Mix.Tasks.Doctor do
  use Mix.Task

  alias Doctor.Config
  alias Doctor.Reporters.{Full, Summary}
  alias Mix.Shell.IO

  @shortdoc "Documentation coverage report"
  @recursive true

  def run(args) do
    result =
      Config.config_file()
      |> load_config_file()
      |> merge_defaults()
      |> merge_cli_args(args)
      |> Doctor.CLI.run_report()

    if result do
      exit({:shutdown, 0})
    else
      exit({:shutdown, 1})
    end
  end

  defp load_config_file(file) do
    if File.exists?(file) do
      IO.info("Doctor file found. Loading configuration.")

      {config, _bindings} = Code.eval_file(file)

      config
    else
      IO.info("Doctor file not found. Using defaults.")

      %{}
    end
  end

  defp merge_defaults(config) do
    Map.merge(Config.config_defaults_as_map(), config)
  end

  defp merge_cli_args(config, args) do
    options =
      args
      |> Enum.reduce(%{}, fn
        "--full", acc ->
          Map.merge(acc, %{reporter: Full})

        "--summary", acc ->
          Map.merge(acc, %{reporter: Summary})

        _, acc ->
          acc
      end)

    Map.merge(config, options)
  end
end