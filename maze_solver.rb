require 'byebug'

class Maze
  def self.new_with_file(filename, maze_chars = {})
    Dir.chdir('mazes') # go to mazes folder
    begin
      rows = File.readlines(filename).map(&:chomp)
    ensure
      Dir.chdir('..') # go back
    end
    grid = rows.map(&:chars)
    self.new(grid, maze_chars)
  end

  attr_reader :grid, :current_pos, :start, :finish

  def initialize(grid, maze_chars = {})
    default_chars = {
      wall: '*',
      start: 'S',
      finish: 'E',
      marker: 'X',
      path: ' '
    }

    @grid = grid
    @maze_chars = default_chars.merge(maze_chars)
    @current_pos = start
  end

  def [](pos)
    row, col = pos
    grid[row][col]
  end

  def []=(pos, marker)
    row, col = pos
    @grid[row][col] = marker
  end

  def start
    find_pos(@maze_chars[:start])
  end

  def finish
    find_pos(@maze_chars[:finish])
  end

  def at_finish?(pos = @current_pos)
    distance(pos, finish) == 1
  end

  def valid_move?(pos1 = @current_pos, pos2)
    distance(pos1, pos2) == 1 && self[pos2] == @maze_chars[:path]
  end

  def valid_moves(initial_pos = @current_pos)
    moves = []
    single_moves(initial_pos).each do |new_pos|
      moves << new_pos if valid_move?(initial_pos, new_pos)
    end
    moves
  end

  def move(pos1 = @current_pos, pos2)
    return nil unless valid_move?(pos1, pos2)
    self[pos2] = @maze_chars[:marker]
    @current_pos = pos2
  end

  def distance(pos1 = @current_pos, pos2)
    x1, y1 = pos1
    x2, y2 = pos2

    (x1 - x2).abs + (y1 - y2).abs
  end

  def single_moves(initial_pos = @current_pos)
    x,y = initial_pos
    [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]
  end

  def display
    puts grid.map { |row| row.join('') }
  end

  private
    def find_pos(chr)
      row = @grid.find { |el| el.include?(chr) }
      [@grid.index(row), row.index(chr)]
    end
end

class Solver
  attr_reader :maze

  def initialize(maze)
    @maze = maze
    @move_tree = {maze.current_pos => nil}
  end

  def solve
    finish = find_finish
    if finish
      solution_path = build_solution_path(finish)
      solution_path.each { |pos| @maze.move(pos) }
    else
      nil
    end
  end


  def find_finish(start = maze.start)
    queue = [start]
    current = queue[0]

    until queue.empty?
      current = queue.shift
      return current if maze.at_finish?(current)

      maze.valid_moves(current).each do |new_pos|
        unless @move_tree.keys.include?(new_pos)
          queue << new_pos
          @move_tree[new_pos] = current
        end
      end
    end
    nil
  end

  def build_solution_path(finish)
    solution_path = [finish]
    current = solution_path.first

    until current == maze.start
      solution_path.unshift(@move_tree[solution_path.first])
      current = @move_tree[solution_path.first]
    end
    solution_path
  end

  def display_solution
    solution_exists = solve
    solution_exists ? @maze.display : (puts "no solution found")
  end
end

if __FILE__ == $PROGRAM_NAME
  file = nil
  while true
    begin
    print "enter filename containing your maze or 'exit' > "
      file = gets.chomp
      break if file == "exit"
      m = Maze.new_with_file(file)
    rescue
      puts "invalid file"
      retry
    end
    puts "Maze:"
    puts m.display

    puts "Solution:"
    Solver.new(m).display_solution
  end
end
