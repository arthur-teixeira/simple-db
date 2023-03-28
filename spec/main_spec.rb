describe "database" do
  before do
    `rm -rf test.db`
  end

  def run_script(commands)
    raw_output = nil
    puts commands
    IO.popen("./db test.db", "r+") do |pipe|
      commands.each do |command| 
        begin
          pipe.puts command 
        rescue Errno::EPIPE
          break
        end
      end
      pipe.close_write

      raw_output = pipe.gets(nil)
    end
    puts raw_output
    raw_output.split("\n")
  end

  it "Inserts and retrieves a row" do
    result =
      run_script(["insert 1 user1 person1@example.com", "select", ".exit"])

    expect(result).to match_array(
      [
        "db > Executed.",
        "db > (1, user1, person1@example.com)",
        "Executed.",
        "db > "
      ]
    )
  end

  it "prints error message when table is full" do
    script = (1..1400).map { |i| "insert #{i} user#{i} person#{i}@example.com" }
    script << ".exit"
    result = run_script(script)
    expect(result.last(2)).to match_array([
      "db > Executed.",
      "db > Need to implement updating parent after split.",
    ])
  end

  it "Allows inserting strings that are the maximum length" do
    long_username = "a"*32
    long_email = "a"*255

    result = run_script([
      "insert 1 #{long_username} #{long_email}",
      "select",
      ".exit",
    ])
    expect(result).to match_array([
      "db > Executed.",
      "db > (1, #{long_username}, #{long_email})",
      "Executed.",
      "db > ",
    ])
  end

  it "Prints error if strings are to long" do
    long_username = "a"*33
    long_email = "a"*256

    result = run_script([
      "insert 1 #{long_username} #{long_email}",
      "select",
      ".exit",
    ])
    expect(result).to match_array([
      "db > String is too long.",
      "db > Executed.",
      "db > ",
    ])
  end

  it "Prints an error if id is negative" do
    result = run_script([
      "insert -1 a b",
      "select",
      ".exit",
    ])
    expect(result).to match_array([
      "db > ID must be positive.",
      "db > Executed.",
      "db > ",
    ])
  end


  it "persists data after connection is closed" do
    result1 = run_script([
      "insert 1 user1 user1@example.com",
      ".exit",
    ])

    expect(result1).to match_array([
      "db > Executed.",
      "db > ",
    ])

    result2 = run_script([
      "select",
      ".exit",
    ])

    expect(result2).to match_array([
      "db > (1, user1, user1@example.com)",
      "Executed.",
      "db > ",
    ])
  end

  it "prints constants" do
    result = run_script([
      ".constants",
      ".exit",
    ])

    expect(result).to match_array([
      "db > Constants:",
      "ROW_SIZE: 293",
      "COMMON_NODE_HEADER_SIZE: 6",
      "LEAF_NODE_HEADER_SIZE: 10",
      "LEAF_NODE_CELL_SIZE: 297",
      "LEAF_NODE_SPACE_FOR_CELLS: 4086",
      "LEAF_NODE_MAX_CELLS: 13",
      "db > ",
    ])
  end

  it "allows printing out the structure of a one-node btree" do
    script = [3, 1, 2].map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".btree"
    script << ".exit"
    result = run_script(script)

    expect(result).to match_array([
      "db > Executed.",
      "db > Executed.",
      "db > Executed.",
      "db > Tree:",
      "- leaf (size 3)",
      "  - 1",
      "  - 2",
      "  - 3",
      "db > "
    ])
  end

  it "prints error if there is a duplicate id" do 
    result = run_script([
      "insert 1 user1 person1@example.com",
      "insert 1 user1 person1@example.com",
      "select",
      ".exit"
    ])

    expect(result).to match_array([
      "db > Executed.",
      "db > Error: Duplicate key.",
      "db > (1, user1, person1@example.com)",
      "Executed.",
      "db > ",
    ])
  end

  it "prints structure of a 3-leaf-node btree" do
    script = (1..14).map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".btree"
    script << "insert 15 user15 person15@example.com"
    script << ".exit"

    result = run_script(script)

    expect(result[14...(result.length)]).to match_array([
      "db > Tree:",
      "- internal (size 1)",
      "  - leaf (size 7)",
      "    - 1",
      "    - 2",
      "    - 3",
      "    - 4",
      "    - 5",
      "    - 6",
      "    - 7",
      "  - key 8",
      "  - leaf (size 7)",
      "    - 8",
      "    - 9",
      "    - 10",
      "    - 11",
      "    - 12",
      "    - 13",
      "    - 14",
      "db > Executed.",
      "db > ",
    ])
  end
end
