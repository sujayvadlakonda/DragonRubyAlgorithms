# A visual demonstration of a breadth first search
# Inspired by https://www.redblobgames.com/pathfinding/a-star/introduction.html

# An animation that can respond to user input in real time

# A breadth first search expands in all directions one step at a time
# The frontier is a queue of cells to be expanded from
# The visited hash allows quick lookups of cells that have been expanded from
# The walls hash allows quick lookup of whether a cell is a wall

# The breadth first search starts by adding the red star to the frontier array
# and marking it as visited
# Each step a cell is removed from the front of the frontier array (queue)
# Unless the neighbor is a wall or visited, it is added to the frontier array
# The neighbor is then marked as visited

# The frontier is blue
# Visited cells are light brown
# Walls are camo green
# Even when walls are visited, they will maintain their wall color

# The star can be moved by clicking and dragging
# Walls can be added and removed by clicking and dragging

class EarlyExitBreadthFirstSearch
  attr_gtk

  def initialize(args)
    # Variables to edit the size and appearance of the grid
    # Freely customizable to user's liking
    args.state.grid.width     = 15
    args.state.grid.height    = 15
    args.state.grid.cell_size = 40

    # At some step the animation will end,
    # and further steps won't change anything (the whole grid will be explored)
    # This step is roughly the grid's width * height
    # When anim_steps equals max_steps no more calculations will occur
    # and the slider will be at the end
    args.state.max_steps  = args.state.grid.width * args.state.grid.height 

    # The location of the star and walls of the grid
    # They can be modified to have a different initial grid
    # Walls are stored in a hash for quick look up when doing the search
    args.state.star   = [0, 0]
    args.state.target = [0, 2]
    args.state.walls  = {}    

    # Variables that are used by the breadth first search
    # Storing cells that the search has visited, prevents unnecessary steps
    # Expanding the frontier of the search in order makes the search expand
    # from the center outward
    args.state.visited               = {}
    args.state.early_exit_visited    = {}
    args.state.frontier              = []
    args.state.came_from             = {}
    args.state.path                  = {}

    # What the user is currently editing on the grid
    # Possible values are: :none, :slider, :star, :remove_wall, :add_wall

    # We store this value, because we want to remember the value even when
    # the user's cursor is no longer over what they're interacting with, but
    # they are still clicking down on the mouse.
    args.state.current_input = :none 
  end

  # This method is called every frame/tick
  # Every tick, the current state of the search is rendered on the screen,
  # User input is processed, and
  # The next step in the search is calculated
  def tick
    if state.visited.empty?
      state.max_steps.times { calc }
      calc_path
    end
    render 
    input  
  end

  # Draws everything onto the screen
  def render
    render_background       
    render_heat_map
    render_walls
    render_path
    render_star
    render_target
  end

  # The methods below subdivide the task of drawing everything to the screen

  # Draws what the grid looks like with nothing on it
  def render_background
    render_unvisited  
    render_grid_lines 
  end

  # Draws a rectangle the size of the entire grid to represent unvisited cells
  def render_unvisited
    rect = [0, 0, grid.width, grid.height]
    outputs.solids << [scale_up(rect), unvisited_color]
    outputs.solids << [early_exit_scale_up(rect), unvisited_color]
  end

  # Draws grid lines to show the division of the grid into cells
  def render_grid_lines
    for x in 0..grid.width
      outputs.lines << vertical_line(x)
      outputs.lines << early_exit_vertical_line(x)
    end

    for y in 0..grid.height
      outputs.lines << horizontal_line(y) 
      outputs.lines << early_exit_horizontal_line(y)
    end
  end

  # Easy way to draw vertical lines given an index
  def vertical_line column
    scale_up([column, 0, column, grid.height])
  end

  # Easy way to draw horizontal lines given an index
  def horizontal_line row
    scale_up([0, row, grid.width, row])
  end

  # Easy way to draw vertical lines given an index
  def early_exit_vertical_line column
    scale_up([column + grid.width + 1, 0, column + grid.width + 1, grid.height])
  end

  # Easy way to draw horizontal lines given an index
  def early_exit_horizontal_line row
    scale_up([grid.width + 1, row, grid.width + grid.width + 1, row])
  end

  # Draws the area that is going to be searched from
  # The frontier is the most outward parts of the search
  def render_frontier
    state.frontier.each do |cell| 
      outputs.solids << [scale_up(cell), frontier_color]
    end
  end

  # Draws the walls
  def render_walls
    state.walls.each_key do |wall| 
      outputs.solids << [scale_up(wall), wall_color]
      outputs.solids << [early_exit_scale_up(wall), wall_color]
    end
  end

  # Renders cells that have been searched in the appropriate color
  def render_visited
    state.visited.each_key do |cell| 
      outputs.solids << [scale_up(cell), visited_color]
    end
  end

  # Renders the star
  def render_star
    outputs.sprites << [scale_up(state.star), 'star.png']
    outputs.sprites << [early_exit_scale_up(state.star), 'star.png']
  end 

  # Renders the target
  def render_target
    outputs.sprites << [scale_up(state.target), 'target.png']
    outputs.sprites << [early_exit_scale_up(state.target), 'target.png']
  end 

  def render_path
    state.path.each_key do | cell |
      outputs.solids << [scale_up(cell), path_color]
      outputs.solids << [early_exit_scale_up(cell), path_color]
    end
  end

  def calc_path
    endpoint = state.target
    while endpoint
      state.path[endpoint] = true
      endpoint = state.came_from[endpoint]
    end
  end

  # Representation of how far away visited cells are from the star
  def render_heat_map
    state.visited.each_key do | visited_cell |
      distance = (state.star.x - visited_cell.x).abs + (state.star.y - visited_cell.y).abs
      max_distance = grid.width + grid.height
      alpha = 255.to_i * distance.to_i / max_distance.to_i
      outputs.solids << [scale_up(visited_cell), red, alpha]
      # outputs.solids << [early_exit_scale_up(visited_cell), red, alpha]
    end

    state.early_exit_visited.each_key do | visited_cell |
      distance = (state.star.x - visited_cell.x).abs + (state.star.y - visited_cell.y).abs
      max_distance = grid.width + grid.height
      alpha = 255.to_i * distance.to_i / max_distance.to_i
      outputs.solids << [early_exit_scale_up(visited_cell), red, alpha]
    end
  end

  # Translates the given cell grid.width + 1 to the right and then scales up
  # Works on rects but NOT on lines
  def early_exit_scale_up(cell)
    cell_clone = cell.clone
    cell_clone.x += grid.width + 1
    scale_up(cell_clone)
  end

  # In code, the cells are represented as 1x1 rectangles
  # When drawn, the cells are larger than 1x1 rectangles
  # This method is used to scale up cells, and lines
  # Objects are scaled up according to the grid.cell_size variable
  # This allows for easy customization of the visual scale of the grid
  def scale_up(cell)
    # Prevents the original value of cell from being edited
    cell = cell.clone

    # If cell is just an x and y coordinate
    if cell.size == 2
      # Add a width and height of 1
      cell << 1
      cell << 1
    end

    # Scale all the values up
    cell.map! { |value| value * grid.cell_size }

    # Returns the scaled up cell
    cell
  end

  # This method processes user input every tick
  # This method allows the user to use the buttons, slider, and edit the grid
  # There are 2 types of input:
  #   Button Input
  #   Click and Drag Input
  #
  #   Button Input is used for the backward step and forward step buttons
  #   Input is detected by mouse up within the bounds of the rect
  #
  #   Click and Drag Input is used for moving the star, adding walls,
  #   removing walls, and the slider
  #
  #   When the mouse is down on the star, the current_input variable is set to :star
  #   While current_input equals :star, the cursor's position is used to calculate the
  #   appropriate drag behavior
  #
  #   When the mouse goes up current_input is set to :none
  #
  #   A variable has to be used because the star has to continue being edited even
  #   when the cursor is no longer over the star
  #
  #   Similar things occur for the other Click and Drag inputs
  def input
    # The detection and processing of click and drag inputs are separate
    # The program has to remember that the user is dragging an object
    # even when the mouse is no longer over that object
    detect_current_input          
    process_current_input         
  end
  # Determines what the user is editing and stores the value
  # Storing the value allows the user to continue the same edit as long as the
  # mouse left click is held
  def detect_current_input
    if inputs.mouse.up                  
      state.current_input = :none          
    elsif star_clicked?                 
      state.current_input = :star          
    elsif star2_clicked?                 
      state.current_input = :star2          
    elsif target_clicked?                 
      state.current_input = :target          
    elsif target2_clicked?                 
      state.current_input = :target2 
    elsif wall_clicked?                 
      state.current_input = :remove_wall   
    elsif wall2_clicked?                 
      state.current_input = :remove_wall2
    elsif grid_clicked?                 
      state.current_input = :add_wall
    elsif grid2_clicked?                 
      state.current_input = :add_wall2
    end
  end

  # Processes click and drag based on what the user is currently dragging
  def process_current_input
    if state.current_input == :star         
      input_star                            
    elsif state.current_input == :star2
      input_star2                            
    elsif state.current_input == :target         
      input_target                            
    elsif state.current_input == :target2         
      input_target2                            
    elsif state.current_input == :remove_wall  
      input_remove_wall                     
    elsif state.current_input == :remove_wall2
      input_remove_wall2                     
    elsif state.current_input == :add_wall     
      input_add_wall                        
    elsif state.current_input == :add_wall2     
      input_add_wall2                        
    end
  end

  # Moves the star to the grid closest to the mouse
  # Only resets the search if the star changes position
  # Called whenever the user is editing the star (puts mouse down on star)
  def input_star
    old_star = state.star.clone 
    state.star = cell_closest_to_mouse
    unless old_star == state.star 
      reset 
    end
  end

  # Moves the star to the grid closest to the mouse
  # Only resets the search if the star changes position
  # Called whenever the user is editing the star (puts mouse down on star)
  def input_star2
    old_star = state.star.clone 
    state.star = cell_closest_to_mouse2
    unless old_star == state.star 
      reset 
    end
  end

  # Moves the target to the grid closest to the mouse
  # Only resets the search if the target changes position
  # Called whenever the user is editing the target (puts mouse down on target)
  def input_target
    old_target = state.target.clone 
    state.target = cell_closest_to_mouse
    unless old_target == state.target 
      reset 
    end
  end

  # Moves the target to the grid closest to the mouse
  # Only resets the search if the target changes position
  # Called whenever the user is editing the target (puts mouse down on target)
  def input_target2
    old_target = state.target.clone 
    state.target = cell_closest_to_mouse2
    unless old_target == state.target 
      reset 
    end
  end

  # Removes walls that are under the cursor
  def input_remove_wall
    # The mouse needs to be inside the grid, because we only want to remove walls
    # the cursor is directly over
    # Recalculations should only occur when a wall is actually deleted
    if mouse_inside_grid? 
      if state.walls.has_key?(cell_closest_to_mouse)
        state.walls.delete(cell_closest_to_mouse) 
        reset 
      end
    end
  end

  # Removes walls that are under the cursor
  def input_remove_wall2
    # The mouse needs to be inside the grid, because we only want to remove walls
    # the cursor is directly over
    # Recalculations should only occur when a wall is actually deleted
    if mouse_inside_grid2? 
      if state.walls.has_key?(cell_closest_to_mouse2)
        state.walls.delete(cell_closest_to_mouse2) 
        reset 
      end
    end
  end

  # Adds walls at cells under the cursor
  def input_add_wall
    if mouse_inside_grid? 
      unless state.walls.has_key?(cell_closest_to_mouse)
        state.walls[cell_closest_to_mouse] = true 
        reset 
      end
    end
  end

  # Adds walls at cells under the cursor
  def input_add_wall2
    if mouse_inside_grid2? 
      unless state.walls.has_key?(cell_closest_to_mouse2)
        state.walls[cell_closest_to_mouse2] = true 
        reset 
      end
    end
  end

  # Whenever the user edits the grid,
  # The search has to be resetd upto the current step
  # with the current grid as the initial state of the grid
  def reset
    # Resets the search
    state.frontier  = [] 
    state.visited   = {} 
    state.early_exit_visited   = {} 
    state.came_from = {} 
    state.path      = {}
  end


  # This method moves the search forward one step
  # When the animation is playing it is called every tick
  # And called whenever the current step of the animation needs to be resetd

  # Moves the search forward one step
  # Parameter called_from_tick is true if it is called from the tick method
  # It is false when the search is being resetd after user editing the grid
  def calc
    # The setup to the search
    # Runs once when the there are no visited cells
    if state.visited.empty?  
      state.visited[state.star] = true              
      state.early_exit_visited[state.star] = true              
      state.frontier << state.star                   
      state.came_from[state.star] = nil
    end

    # A step in the search
    unless state.frontier.empty? 
      # Takes the next frontier cell
      new_frontier = state.frontier.shift 
      # For each of its neighbors
      adjacent_neighbors(*new_frontier).each do |neighbor| 
        # That have not been visited and are not walls
        unless state.visited.has_key?(neighbor) || state.walls.has_key?(neighbor) 
          # Add them to the frontier and mark them as visited
          state.visited[neighbor] = true 
          unless state.visited.has_key?(state.target)
            state.early_exit_visited[neighbor] = true
          end
          state.frontier << neighbor 
          state.came_from[neighbor] = new_frontier
        end
      end
    end
  end
  

  # Returns a list of adjacent cells
  # Used to determine what the next cells to be added to the frontier are
  def adjacent_neighbors(x, y)
    neighbors = [] 

    neighbors << [x, y - 1] unless y == 0 
    neighbors << [x - 1, y] unless x == 0 
    neighbors << [x, y + 1] unless y == grid.height - 1 
    neighbors << [x + 1, y] unless x == grid.width - 1 

    neighbors = neighbors.sort_by { |neighbor_x, neighbor_y|  proximity_to_star(neighbor_x, neighbor_y) }

    neighbors 
  end

  def proximity_to_star(x, y)
    distance_x = (state.star.x - x).abs
    distance_y = (state.star.y - y).abs

    if distance_x > distance_y
      return distance_x
    else
      return distance_y
    end
  end

  # When the user grabs the star and puts their cursor to the far right
  # and moves up and down, the star is supposed to move along the grid as well
  # Finding the cell closest to the mouse helps with this
  def cell_closest_to_mouse
    # Closest cell to the mouse
    x = (inputs.mouse.point.x / grid.cell_size).to_i 
    y = (inputs.mouse.point.y / grid.cell_size).to_i 
    # Bound x and y to the grid
    x = grid.width - 1 if x > grid.width - 1 
    y = grid.height - 1 if y > grid.height - 1 
    # Return closest cell
    [x, y] 
  end

  # When the user grabs the star and puts their cursor to the far right
  # and moves up and down, the star is supposed to move along the grid as well
  # Finding the cell closest to the mouse helps with this
  def cell_closest_to_mouse2
    # Closest cell to the mouse
    x = (inputs.mouse.point.x / grid.cell_size).to_i 
    y = (inputs.mouse.point.y / grid.cell_size).to_i 
    # Translate the cell to the original grid
    x -= grid.width + 1
    # Bound x and y to the grid
    x = grid.width - 1 if x > grid.width - 1 
    y = grid.height - 1 if y > grid.height - 1 
    # Return closest cell
    [x, y] 
  end

  # Signal that the user is going to be moving the star
  def star_clicked?
    inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(state.star))
  end

  # Signal that the user is going to be moving the star
  def star2_clicked?
    inputs.mouse.down && inputs.mouse.point.inside_rect?(early_exit_scale_up(state.star))
  end

  # Signal that the user is going to be moving the target
  def target_clicked?
    inputs.mouse.down && inputs.mouse.point.inside_rect?(scale_up(state.target))
  end

  # Signal that the user is going to be moving the target
  def target2_clicked?
    inputs.mouse.down && inputs.mouse.point.inside_rect?(early_exit_scale_up(state.target))
  end

  # Signal that the user is going to be removing walls
  def wall_clicked?
    inputs.mouse.down && mouse_inside_wall?
  end

  # Signal that the user is going to be removing walls
  def wall2_clicked?
    inputs.mouse.down && mouse_inside_wall2?
  end

  # Signal that the user is going to be adding walls
  def grid_clicked?
    inputs.mouse.down && mouse_inside_grid?
  end

  # Signal that the user is going to be adding walls
  def grid2_clicked?
    inputs.mouse.down && mouse_inside_grid2?
  end

  # Returns whether the mouse is inside of a wall
  # Part of the condition that checks whether the user is removing a wall
  def mouse_inside_wall?
    state.walls.each_key do | wall |
      return true if inputs.mouse.point.inside_rect?(scale_up(wall))
    end

    false
  end

  # Returns whether the mouse is inside of a wall
  # Part of the condition that checks whether the user is removing a wall
  def mouse_inside_wall2?
    state.walls.each_key do | wall |
      return true if inputs.mouse.point.inside_rect?(early_exit_scale_up(wall))
    end

    false
  end
  # Returns whether the mouse is inside of a grid
  # Part of the condition that checks whether the user is adding a wall
  def mouse_inside_grid?
    inputs.mouse.point.inside_rect?(scale_up([0, 0, grid.width, grid.height]))
  end

  # Returns whether the mouse is inside of a grid
  # Part of the condition that checks whether the user is adding a wall
  def mouse_inside_grid2?
    inputs.mouse.point.inside_rect?(early_exit_scale_up([0, 0, grid.width, grid.height]))
  end

  # These methods provide handy aliases to colors

  # Light brown
  def unvisited_color
    [221, 212, 213] 
  end

  # White
  def grid_line_color
    [255, 255, 255] 
  end

  # Dark Brown
  def visited_color
    [204, 191, 179] 
  end

  # Blue
  def frontier_color
    [103, 136, 204] 
  end

  # Camo Green
  def wall_color
    [134, 134, 120] 
  end

  # Button Background
  def gray
    [190, 190, 190]
  end

  # Button Outline
  def black
    [0, 0, 0]
  end

  # Pastel White
  def path_color
    [231, 230, 228]
  end

  def red
    [255, 0 , 0]
  end

  # These methods make the code more concise
  def grid
    state.grid
  end

  def buttons
    state.buttons
  end

  def slider
    state.slider
  end
end

# Method that is called by DragonRuby periodically
# Used for updating animations and calculations
def tick args

  # Pressing r will reset the application
  if args.inputs.keyboard.key_down.r
    args.gtk.reset
    reset
    return
  end

  # Every tick, new args are passed, and the Breadth First Search tick is called
  $early_exit_breadth_first_search ||= EarlyExitBreadthFirstSearch.new(args)
  $early_exit_breadth_first_search.args = args
  $early_exit_breadth_first_search.tick
end


def reset
  $early_exit_breadth_first_search = nil
end
