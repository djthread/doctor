defmodule Mix.Tasks.Doctor do
  @moduledoc false

  use Mix.Task

  alias Doctor.Config
  alias Doctor.Reporters.{Full, Short, Summary}

  @shortdoc "Documentation coverage report"
  @recursive true

  @doc """
  This Mix task generates a Doctor report of the project.
  """
  def run(args) do
    config =
      Config.config_file()
      |> load_config_file()
      |> merge_defaults()
      |> merge_cli_args(args)

    result = Doctor.CLI.run_report(config)

    unless result do
      System.at_exit(fn _ ->
        exit({:shutdown, 1})
      end)

      if config.raise do
        Mix.raise("Doctor has encountered an error.")
      end
    end

    :ok
  end

  defp load_config_file(file) do
    # If we are performing this operation on an umbrella app then look to
    # the project root for the config file
    file =
      if Mix.Task.recursing?() do
        Path.join(["..", "..", file])
      else
        file
      end

    if File.exists?(file) do
      Mix.shell().info("Doctor file found. Loading configuration.")

      {config, _bindings} = Code.eval_file(file)

      config
    else
      Mix.shell().info("Doctor file not found. Using defaults.")

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

        "--short", acc ->
          Map.merge(acc, %{reporter: Short})

        "--summary", acc ->
          Map.merge(acc, %{reporter: Summary})

        "--raise", acc ->
          Map.merge(acc, %{raise: true})

        _, acc ->
          acc
      end)

    Map.merge(config, options)
  end
end
