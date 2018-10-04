defmodule Doctor.ModuleInformation do
  @moduledoc """
  """

  alias __MODULE__
  alias Doctor.{Docs, Specs}

  defstruct ~w(module file_full_path file_relative_path file_ast docs_version module_doc metadata docs specs user_defined_functions)a

  @doc """
  Breaks down the docs format entry returned from Code.fetch_docs(MODULE)
  """
  def build({docs_version, _annotation, _language, _format, module_doc, metadata, docs}, module) do
    {:ok, module_specs} = Code.Typespec.fetch_specs(module)

    %ModuleInformation{
      module: module,
      file_full_path: get_full_file_path(module),
      file_relative_path: get_relative_file_path(module),
      file_ast: nil,
      docs_version: docs_version,
      module_doc: module_doc,
      metadata: metadata,
      docs: Enum.map(docs, &Docs.build/1),
      specs: Enum.map(module_specs, &Specs.build/1),
      user_defined_functions: nil
    }
  end

  def load_file_ast(%ModuleInformation{} = module_info) do
    ast =
      module_info.file_full_path
      |> File.read!()
      |> Code.string_to_quoted!()

    %{module_info | file_ast: ast}
  end

  def load_user_defined_functions(%ModuleInformation{} = module_info) do
    {_ast, functions} = Macro.prewalk(module_info.file_ast, [], &parse_ast_node_for_def/2)

    %{module_info | user_defined_functions: functions}
  end

  defp get_full_file_path(module) do
    module.module_info()
    |> Keyword.get(:compile)
    |> Keyword.get(:source)
    |> to_string()
  end

  defp get_relative_file_path(module) do
    module
    |> get_full_file_path()
    |> Path.relative_to(File.cwd!())
  end

  defp parse_ast_node_for_def(
         {:def, _def_line,
          [{:when, _line_when, [{function_name, _function_line, args}, _guard]}, _do_block]} =
           tuple,
         acc
       ) do
    {tuple, [{function_name, get_function_arity(args)} | acc]}
  end

  defp parse_ast_node_for_def(
         {:def, _def_line, [{function_name, _function_line, args}, _do_block]} = tuple,
         acc
       ) do
    {tuple, [{function_name, get_function_arity(args)} | acc]}
  end

  defp parse_ast_node_for_def(tuple, acc) do
    {tuple, acc}
  end

  defp get_function_arity(nil), do: 0
  defp get_function_arity(args), do: length(args)
end