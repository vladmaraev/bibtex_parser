defmodule BibtexParser.Parser do
  @moduledoc false
  import NimbleParsec
  import BibtexParser.Parser.Helpers
  require Logger

  # ------------------------------------ Components ----------------------------#

  #
  # Comment: Parses a comment in a bibtex file.
  #

  comment =
    whitespaces()
    |> concat(ascii_char([?%]))
    |> repeat(
      lookahead_not(ascii_char([?\n]))
      |> utf8_char([])
    )
    |> ignore()

  comments = repeat(comment) |> concat(newlines())

  defparsec(:comments, comments, debug: false)

  #
  # Tag: Parses a field in a bibtex file. (E.g., author, title, pages,..)
  #

  tag =
    whitespaces()
    |> concat(ignore_optional_char(?,))
    |> concat(symbol())
    |> repeat(
      lookahead_not(ascii_char([?=]))
      |> ascii_char([?A..?Z, ?a..?z, ?., ?0..?9, ?,, ?:, ?/])
    )
    |> concat(whitespaces())
    |> concat(ignore_optional_char(?,))
    |> concat(whitespaces())

  defparsec(:tag, tag, debug: false)

  #
  # Argument: The value of a bibtex field. Currently the string in between quotes.
  #

  hashtag = ignore_required_char(?#)

  quoted_tag_content_concat =
    whitespaces()
    |> concat(ignore_required_char(?"))
    |> ascii_char([])
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> ascii_char([])
    )
    |> concat(whitespaces())
    |> concat(ignore_optional_char(?"))
    |> concat(whitespaces())

  defparsec(
    :quoted,
    quoted_tag_content_concat |> optional(hashtag |> parsec(:quoted)),
    debug: false
  )

  number_value =
    whitespaces()
    |> repeat(
      lookahead_not(ascii_char([{:not, ?0..?9}]))
      |> ascii_char([?0..?9])
    )
    |> concat(whitespaces())
    |> concat(ignore_optional_char(?,))
    |> concat(whitespaces())

  trimmable =
    choice([
      replace(ascii_char([?\n]), ?\s) |> concat(whitespaces()),
      choice([ascii_char([?\s]), ascii_char([?\s])]) |> concat(whitespaces()),
      ascii_char([])
    ])

  regular_content = trimmable

  defparsec(
    :wrapped_in_braces,
    ascii_char([?{])
    |> repeat(
      lookahead_not(ascii_char([?}]))
      |> choice([parsec(:wrapped_in_braces), regular_content])
    )
    |> ascii_char([?}])
  )

  braced =
    whitespaces()
    |> concat(ignore_required_char(?{))
    |> repeat(
      lookahead_not(ascii_char([?}]))
      |> choice([parsec(:wrapped_in_braces), regular_content])
    )
    |> concat(whitespaces())
    |> concat(ignore_required_char(?}))
    |> concat(whitespaces())
    |> concat(ignore_optional_char(?,))
    |> concat(whitespaces())

  defparsec(:braced, braced, debug: false)

  tag_content =
    whitespaces()
    |> concat(ignore_required_char(?=))
    |> concat(whitespaces())
    |> choice([parsec(:quoted), braced, number_value])
    |> concat(ignore_optional_char(?,))

  defparsec(:tag_content, tag_content, debug: false)

  #
  # Type: Parses the type from the bibtex entry. E.g., book, article, ..
  #

  type =
    whitespaces()
    |> concat(ignore_required_char(?@))
    |> concat(whitespaces())
    |> ascii_char([])
    |> repeat(
      lookahead_not(ascii_char([?{]))
      |> ascii_char([?A..?Z, ?a..?z, ?., ?0..?9, ?,, ?:, ?/])
    )
    |> concat(whitespaces())

  defparsec(:type, type, debug: false)

  #
  # Ref_label: Parses the reference label from the bibtex.
  #

  ref_label =
    ignore_required_char(?{)
    |> concat(whitespaces())
    |> concat(symbol())
    |> repeat(
      lookahead_not(choice([ascii_char([?,]), ascii_char([?\s])]))
      |> ascii_char([?A..?Z, ?a..?z, ?., ?0..?9, ?,, ?:, ?/, ?-, ?_])
    )
    |> concat(whitespaces())
    |> concat(ignore_optional_char(?,))

  defparsec(:label, ref_label, debug: false)

  # ------------------------------------ File ----------------------------------#

  #
  # Helpers: Higher-level parser functions.
  #

  defparsec(:typelabel, type |> concat(ref_label), debug: false)

  defparsec(:eatbrace, whitespaces() |> concat(ignore_optional_char(?})) |> concat(whitespaces()),
    debug: false
  )

  def parse_entries(content) do
    with {:ok, [], rest, _, _, _} <- comments(content),
         {:ok, entry, r} <- parse_entry(rest) do
      {entries, rest} = parse_entries(r)
      {[entry | entries], rest}
    else
      {:error, _e, rest} ->
        {[], rest}
    end
  end

  def parse_entry(input) do
    with {:ok, type, rest} <- parse_type(input),
         {:ok, label, rest} <- parse_label(rest),
         {tags, rest} <- parse_tags(rest),
         {:ok, _, rest, _, _, _} <- eatbrace(rest) do
      {:ok, %{:type => type, :label => label, :tags => tags}, rest}
    else
      {:error, e, rest} ->
        {:error, e, rest}
    end
  end

  @doc false
  def parse_type(input) do
    Logger.debug("Parsing type: #{input}")
    result = type(input)

    case result do
      {:ok, result, rest, _, _, _} ->
        result = to_string(result)
        {:ok, result, rest}

      {:error, e, _, _, _, _} ->
        {:error, e, input}
    end
  end

  def parse_label(input) do
    Logger.debug("Parsing label: #{input}")

    result = label(input)

    case result do
      {:ok, result, rest, _, _, _} ->
        result = to_string(result)
        {:ok, result, rest}

      {:error, e, _, _, _, _} ->
        {:error, e, input}
    end
  end

  def parse_tags(input) do
    Logger.debug("Parsing tags: #{input}")

    result = parse_tag(input)

    case result do
      {:ok, {tag, content}, rest} ->
        tag = String.downcase(to_string(tag))
        content = to_string(content)
        {tags, rest} = parse_tags(rest)
        {[{tag |> String.to_atom(), content} | tags], rest}

      {:error, _e, input} ->
        {[], input}
    end
  end

  def parse_tag(input) do
    Logger.debug("Parsing tag: #{input}")

    with {:ok, name, rest} <- parse_tag_name(input),
         {:ok, cont, rest} <- parse_tag_content(rest) do
      {:ok, {name, cont}, rest}
    else
      {:error, e, _} ->
        {:error, e, input}

      {:error, e, _, _, _, _} ->
        {:error, "parse_tag: #{e}", input}
    end
  end

  def parse_tag_name(input) do
    Logger.debug("Parsing tag name: #{input}")

    result = tag(input)

    case result do
      {:ok, result, rest, _, _, _} ->
        {:ok, result, rest}

      {:error, e, _, _, _, _} ->
        {:error, "parse_tag_name: #{e}", input}
    end
  end

  def parse_tag_content(input) do
    Logger.debug("Parsing tag content: #{input}")

    result = tag_content(input)

    case result do
      {:ok, result, rest, _, _, _} ->
        {:ok, result, rest}

      {:error, e, _, _, _, _} ->
        {:error, "parse_tag_content: #{e}", input}
    end
  end
end
