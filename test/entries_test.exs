defmodule BibtexParser.Test.Entries do
  use ExUnit.Case
  doctest BibtexParser
  alias BibtexParser.Parser

  test "Entry Test 0" do
    input = """
    @misc{ Nobody06,
           author = "Nobody Jr",
           title = "My Article",
           year = 2006,
          pages = "1--10", }
    """

    result = %{
      label: "Nobody06",
      tags: [
        author: "Nobody Jr",
        title: "My Article",
        year: "2006",
        pages: "1--10"
      ],
      type: "misc"
    }

    {:ok, ^result, ""} = Parser.parse_entry(input)
  end

  test "Entry Test Underscore" do
    input = """
    @misc{ Nobody_06,
           author = "Nobody Jr",
           title = "My Article",
           year = 2006,
          pages = "1--10", }
    """

    result = %{
      label: "Nobody_06",
      tags: [
        author: "Nobody Jr",
        title: "My Article",
        year: "2006",
        pages: "1--10"
      ],
      type: "misc"
    }

    {:ok, ^result, ""} = Parser.parse_entry(input)
  end

  test "Entry Test Dash" do
    input = """
    @misc{ Nobody-06,
           author = "Nobody Jr",
           title = "My Article",
           year = 2006,
          pages = "1--10", }
    """

    result = %{
      label: "Nobody-06",
      tags: [
        author: "Nobody Jr",
        title: "My Article",
        year: "2006",
        pages: "1--10"
      ],
      type: "misc"
    }

    {:ok, ^result, ""} = Parser.parse_entry(input)
  end

  test "Entry Test 1" do
    input = """
    @misc{ Nobody06,
           author = "Nobody Jr",
           title = "My Article",
           year = "2006",
          pages = "1--10", }
    """

    result = %{
      label: "Nobody06",
      tags: [
        author: "Nobody Jr",
        title: "My Article",
        year: "2006",
        pages: "1--10"
      ],
      type: "misc"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 2" do
    input = """
    @techreport{agha1985actors,
      title="Actors: A model of concurrent computation in distributed systems.",
      author="Agha, Gul A",
      year="1985",
      institution="MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB"
    }
    """

    result = %{
      label: "agha1985actors",
      tags: [
        title: "Actors: A model of concurrent computation in distributed systems.",
        author: "Agha, Gul A",
        year: "1985",
        institution: "MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 3" do
    input = """
    @techreport{agha1985actors,
      title={Actors: A model of concurrent computation in distributed systems.},
      author={Agha, Gul A},
      year={1985},
      institution={MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB}
    }
    """

    result = %{
      label: "agha1985actors",
      tags: [
        title: "Actors: A model of concurrent computation in distributed systems.",
        author: "Agha, Gul A",
        year: "1985",
        institution: "MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 4" do
    input = """
    @techreport{bobscoolpaper,
      title="Elixir" # " is " # "the bees" # " " # "knees",
      author="Jose " # "Valim",
      year={1985},
      institution={MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB}
    }
    """

    result = %{
      label: "bobscoolpaper",
      tags: [
        title: "Elixir is the bees knees",
        author: "Jose Valim",
        year: "1985",
        institution: "MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 5" do
    input = """
                      @techreport{bobscoolpaper,
      title="Elixir" # " is " # "the bees" # " " # "knees",
      author="Jose " # "Valim",
      year={1985},
      institution={MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB}
    }
    """

    result = %{
      label: "bobscoolpaper",
      tags: [
        title: "Elixir is the bees knees",
        author: "Jose Valim",
        year: "1985",
        institution: "MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 6: special chars in label" do
    input = """
    @techreport{DBLP:conf/cbse/RusselloMD08,
      title="Elixir" # " is " # "the bees" # " " # "knees",
      author="Jose " # "Valim",
      year={1985},
      institution={MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB}
    }
    """

    result = %{
      label: "DBLP:conf/cbse/RusselloMD08",
      tags: [
        title: "Elixir is the bees knees",
        author: "Jose Valim",
        year: "1985",
        institution: "MASSACHUSETTS INST OF TECH CAMBRIDGE ARTIFICIAL INTELLIGENCE LAB"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 7: Nested Bracing preserves capitalization" do
    input = """
    @techreport{foo,
      title="Elixir {Rules}",
    }
    """

    result = %{
      label: "foo",
      tags: [
        title: "Elixir {Rules}"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 8: Braces in title" do
    input = """
    @techreport{foo,
    title     = {{ESCAPE:} {A} Component-Based Policy Framework for Sense and React Applications},
    }
    """

    result = %{
      label: "foo",
      tags: [
        title: "{ESCAPE:} {A} Component-Based Policy Framework for Sense and React Applications"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 9: Braces in title" do
    input = """
    @techreport{foo,
    title     = "{{{This}}} is stupid",
    }
    """

    result = %{
      label: "foo",
      tags: [
        title: "{{{This}}} is stupid"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 10: newlines ignored" do
    input = """
    @techreport{foo,
    title     = {This is a
    multiline
    title},
    }
    """

    result = %{
      label: "foo",
      tags: [
        title: "This is a multiline title"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 11: multiple spaces ignored" do
    input = """
    @techreport{foo,
    title     = {A               title},
    }
    """

    result = %{
      label: "foo",
      tags: [
        title: "A title"
      ],
      type: "techreport"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "Entry Test 12: Special characters" do
    input = """
    @inproceedings{DBLP:conf/icsnc/RubioDT07,
    author    = {Bartolom{\'{e}}}
    }
    """

    result = %{
      label: "DBLP:conf/icsnc/RubioDT07",
      tags: [
        author: "Bartolom{\'{e}}"
      ],
      type: "inproceedings"
    }

    {:ok, ^result, _} = Parser.parse_entry(input)
  end

  test "File with comments and multiple entires" do
    file = """
    %  a sample bibliography file
    %

    @article{small,
    author = {Freely, I.P.},
    title = {A small paper},
    journal = {The journal of small papers},
    volume = {-1},
    note = {to appear},
    }

    @article{big,
    author = {Jass, Hugh},
    title = {A big paper},
    journal = {The journal of big papers},
    volume = {MCMXCVII},
    }

    %  The authors mentioned here are almost, but not quite,
    %  entirely unrelated to Matt Groening.
    """

    result =
      {[
         %{
           label: "small",
           tags: [
             author: "Freely, I.P.",
             title: "A small paper",
             journal: "The journal of small papers",
             volume: "-1",
             note: "to appear"
           ],
           type: "article"
         },
         %{
           label: "big",
           tags: [
             author: "Jass, Hugh",
             title: "A big paper",
             journal: "The journal of big papers",
             volume: "MCMXCVII"
           ],
           type: "article"
         }
       ], ""}

    assert result == Parser.parse_entries(file)
  end
end
