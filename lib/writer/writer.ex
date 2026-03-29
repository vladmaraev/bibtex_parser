defmodule BibtexParser.Writer do
  @moduledoc false

  def to_string(entries) when is_list(entries) do
    entries
    |> Enum.map(&BibtexParser.Writer.to_string/1)
    |> Enum.join("\n\n")
  end

  def to_string(entry) do
    entry = sanitize(entry)

    lines = ["@#{entry.type}{#{entry.label}"]

    lines =
      entry.tags
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.filter(fn {_tag, content} ->
        content != ~c""
      end)
      |> Enum.reduce(lines, fn {tag, value}, lines ->
        line = "    #{tag} = {#{value}}"
        lines ++ [line]
      end)

    lines = lines ++ ["}"]
    Enum.join(lines, ",\n")
  end

  defp sanitize(entry) do
    type = Kernel.to_string(entry.type)
    Map.put(entry, :type, String.downcase(type))
  end
end
