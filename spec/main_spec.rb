describe "database" do
  def run_script(commands)
    raw_output = nil
    IO.popen("./db", "r+") do |pipe|
      commands.each { |command| pipe.puts command }
      pipe.close_write

      raw_output = pipe.gets(nil)
    end
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
    script = (1..1401).map { |i| "insert #{i} user#{i} person#{i}@example.com" }
    script << ".exit"
    result = run_script(script)
    expect(result[-2]).to eq("db > Error: Table full.")
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
end
