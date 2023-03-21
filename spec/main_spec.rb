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
end
