module Todo::Parser
  def get_epics(lines)
    lines
      .select {|line| line.match(/^#/)}
      .map {|line| line.match(/^#(\w+)/)[1]}
  end

  def get_tasks(lines)
    lines
      .select {|line| line.match(/^(-|\+|\*)/)}
      .map {|line| Todo::Story.new(line)}
  end
end