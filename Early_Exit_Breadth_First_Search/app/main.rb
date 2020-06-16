class BreadthFirstSearch
  attr_gtk

  def initialize(args)
    # Variables to edit the size and appearance of the grid
    # Freely customizable to user's liking
    args.state.grid.width     = 30
    args.state.grid.height    = 15
    args.state.grid.tile_size = 40

    # Stores which step of the animation is being rendered
    # When the user moves the star or messes with the walls,
    # the breadth first search is recalculated up to this step
    args.state.anim_steps = 0 

    # At some step the animation will end,
    # and further steps won't change anything (the whole grid will be explored)
    # This step is roughly the grid's width * height
    # When anim_steps equals max_steps no more calculations will occur
    # and the slider will be at the end
    args.state.max_steps  = args.state.grid.width * args.state.grid.height 

    # Whether the animation should play or not
    # If true, every tick moves anim_steps forward one
    # Pressing the stepwise animation buttons will pause the animation
    args.state.play       = true 

    # The location of the star and walls of the grid
    # They can be modified to have a different initial grid
    # Walls are stored in a hash for quick look up when doing the search
    args.state.star       = [0, 0]
    args.state.walls      = {}    

    # Variables that are used by the breadth first search
    # Storing cells that the search has visited, prevents unnecessary steps
    # Expanding the frontier of the search in order makes the search expand
    # from the center outward
    args.state.visited    = {}
    args.state.frontier   = []


    # What the user is currently editing on the grid
    # Possible values are: :none, :slider, :star, :remove_wall, :add_wall

    # We store this value, because we want to remember the value even when
    # the user's cursor is no longer over what they're interacting with, but
    # they are still clicking down on the mouse.
    args.state.user_input = :none 
  end

  # This method is called every frame/tick
  # Every tick, the current state of the search is rendered on the screen,
  # User input is processed, and
  # The next step in the search is calculated
  def tick
    render 
    input  
    calc(true)
  end

  # Draws everything onto the screen
  def render
    render_animation_buttons
    render_slider
    render_background       

    render_visited 
    render_frontier
    render_walls
    render_star
  end

  # The methods below subdivide the task of drawing everything to the screen

  # Draws the buttons that control the animation step and state
  # x, y, w, h can be changed to move the button to a more convenient location
  def render_animation_buttons
    render_previous_step_button
    render_play_button
    render_next_step_button
  end

  def render_previous_step_button
    x, y, w, h = 450, 600, 50, 50
    left_button.rect  = [x, y, w, h, light_gray]
    left_button.label = [x + 20, y + 35, "<"]
    outputs.solids << left_button.rect
    outputs.labels << left_button.label
  end

  def render_play_button
    x, y, w, h = 500, 600, 200, 50
    text = state.play ? "Pause Animation" : "Play Animation"
    center_button.rect   = [x, y, w, h, dark_gray]
    center_button.label  = [x + 37, y + 35, text]
    outputs.solids << center_button.rect
    outputs.labels << center_button.label
  end

  def render_next_step_button
    x, y, w, h = 700, 600, 50, 50
    right_button.rect  = [x, y, w, h, light_gray]
    right_button.label = [x + 20, y + 35, ">"]
    outputs.solids << right_button.rect
    outputs.labels << right_button.label
  end

  # Draws the slider
  # Called every tick
  def render_slider
    # Using primitives hides the line under the white circle of the slider
    outputs.primitives  << [400, 675, 400 + state.max_steps , 675, 0, 0, 0].line 
    outputs.primitives << [380 + state.anim_steps, 655, 37, 37, 'sprites/circle-white.png'].sprite 
  end

  # Draws what the grid looks like with nothing on it
  def render_background
    render_unvisited  
    render_grid_lines 
  end

  # Draws a rectangle the size of the entire grid to represent unvisited cells
  def render_unvisited
    outputs.solids << [0, 0, grid.width * grid.tile_size, grid.height * grid.tile_size, unvisited_color]
  end

  # Draws grid lines to show the division of the grid into cells
  def render_grid_lines
    for x in 0..grid.width
      outputs.lines << vertical_line(x)
    end

    for y in 0..grid.height
      outputs.lines << horizontal_line(y) 
    end
  end

  # Tile Size is used when rendering to allow the grid to be scaled up or down

  # Easy way to draw vertical lines given an index
  def vertical_line column
    [column * grid.tile_size, 0, column * grid.tile_size, grid.height * grid.tile_size, grid_line_color] 
  end

  # Easy way to draw horizontal lines given an index
  def horizontal_line row
    [0, row * grid.tile_size, grid.width * grid.tile_size, row * grid.tile_size, grid_line_color]
  end

  # Draws the area that is going to be searched from
  # The frontier is the most outward parts of the search
  def render_frontier
    state.frontier.each do |x, y| 
      outputs.solids << [x * grid.tile_size, y * grid.tile_size, grid.tile_size, grid.tile_size, frontier_color]
    end
  end

  # Draws the walls
  def render_walls
    state.walls.each_key do |x, y| 
      outputs.solids << [x * grid.tile_size, y * grid.tile_size, grid.tile_size, grid.tile_size, wall_color]
    end
  end

  # Renders cells that have been searched in the appropriate color
  def render_visited
    state.visited.each_key do |x, y| 
      outputs.solids << [x * grid.tile_size, y * grid.tile_size, grid.tile_size, grid.tile_size, visited_color]
    end
  end

  # Renders the star
  def render_star
  outputs.sprites << [state.star.x * grid.tile_size, state.star.y * grid.tile_size, grid.tile_size, grid.tile_size, 'star.png']
  end 


  # This method processes user input every tick
  def input
    # Checks whether any of the buttons are being clicked
    input_buttons

    # The inputs that are non-button are separately controlled
    # Because the code needs to remember what the user was editing
    # even if the mouse is no longer over the relevant object
    detect_user_input          
    process_user_input         
  end

  # Detects and Process input for each button
  def input_buttons
    input_play_button          
    input_previous_step_button 
    input_next_step_button     
  end

  # Controls the play/pause button
  # Inverses whether the animation is playing or not when clicked
  def input_play_button
    if animation_center_button_clicked?
      state.play = !state.play         
    end
  end

  # Checks if the next step button is clicked
  # If it is, it pauses the animation and moves the search one step forward
  def input_next_step_button
    if animation_right_button_clicked?
      state.play = false              
      state.anim_steps += 1           
      calc(false)                     
    end
  end

  # Checks if the previous step button is clicked
  # If it is, it pauses the animation and moves the search one step backward
  def input_previous_step_button 
    if animation_left_button_clicked?
      state.play = false
      state.anim_steps -= 1
      recalculate
    end
  end

  # Determines what the user is editing and stores the value
  # Storing the value allows the user to continue the same edit as long as the
  # mouse left click is held
  def detect_user_input
    if inputs.mouse.up                  
      state.user_input = :none          
    elsif star_clicked?                 
      state.user_input = :star          
    elsif wall_clicked?                 
      state.user_input = :remove_wall   
    elsif grid_clicked?                 
      state.user_input = :add_wall      
    elsif slider_clicked?               
      state.user_input = :slider        
    end
  end

  # Processes input based on what the user is currently editing
  def process_user_input
    if state.user_input == :slider          
      input_slider                          
    elsif state.user_input == :star         
      input_star                            
    elsif state.user_input == :remove_wall  
      input_remove_wall                     
    elsif state.user_input == :add_wall     
      input_add_wall                        
    end
  end

  # This method is called when the user is editing the slider
  # It pauses the animation and moves the white circle to the closest integer point
  # on the slider
  def input_slider
    state.play = false 
    slider_x = inputs.mouse.point.x.to_i 
    slider_x = 400 if slider_x < 400 
    slider_x = 850 if slider_x > 850 
    slider_x -= 20 
    state.anim_steps = slider_x - 380 
    recalculate 
  end

  # Moves the star to the grid closest to the mouse
  # Only recalculates the search if the star changes position
  # Called whenever the user is editing the star (puts mouse down on star)
  def input_star
    old_star = state.star.clone 
    x, y = *grid_closest_to_mouse 
    state.star = [x, y] if x && y 
    unless old_star == state.star 
      recalculate 
    end
  end

  # Removes walls that are under the cursor
  def input_remove_wall
    # The mouse needs to be inside the grid, because we only want to remove walls
    # the cursor is directly over
    if mouse_inside_grid? 
      state.walls.delete(grid_closest_to_mouse) 
      recalculate 
    end
  end

  # Adds walls at cells under the cursor
  def input_add_wall
    if mouse_inside_grid? 
      # Adds a wall to the hash
      # We can use the grid closest to mouse, because the cursor is inside the grid
      state.walls[grid_closest_to_mouse] = true 
      recalculate 
    end
  end

  # Whenever the user edits the grid,
  # The search has to be recalculated upto the current step
  # with the current grid as the initial state of the grid
  def recalculate
    # Resets the search
    state.frontier = [] 
    state.visited = {} 

    # Moves the animation forward one step at a time
    state.anim_steps.times { calc(false) } 
  end


  # This method moves the search forward one step
  # When the animation is playing it is called every tick
  # And called whenever the current step of the animation needs to be recalculated

  # Moves the search forward one step
  # Parameter called_from_tick is true if it is called from the tick method
  # It is false when the search is being recalculated after user editing the grid
  def calc(called_from_tick)

    # If the search is being moved forward by the tick method
    if called_from_tick 
      # It should not if the maximum animation step has been reached
      return unless state.anim_steps < state.max_steps 
      # Or if the animation is paused
      return unless state.play                         
      # The current step of the search that is being animated is incremented
      # This variable is used for recalculating the search when the grid is edited
      state.anim_steps += 1 
    end

    # The setup to the search
    # Runs once when the there is no frontier or visited cells
    if state.frontier.empty? && state.visited.empty?  
      state.frontier << state.star                   
      state.visited[state.star] = true              
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
          state.frontier << neighbor 
          state.visited[neighbor] = true 
        end
      end
    end
  end
  

  # Returns a list of adjacent cells
  # Used to determine what the next cells to be added to the frontier are
  def adjacent_neighbors x, y
    neighbors = [] 

    neighbors << [x, y + 1] unless y == grid.height - 1 
    neighbors << [x + 1, y] unless x == grid.width - 1 
    neighbors << [x, y - 1] unless y == 0 
    neighbors << [x - 1, y] unless x == 0 

    neighbors 
  end

  # When the user grabs the star and puts their cursor to the far right
  # and moves up and down, the star is supposed to move along the grid as well
  # Finding the grid closest to the mouse helps with this
  def grid_closest_to_mouse
    x = (inputs.mouse.point.x / grid.tile_size).to_i 
    y = (inputs.mouse.point.y / grid.tile_size).to_i 
    x = grid.width - 1 if x > grid.width - 1 
    y = grid.height - 1 if y > grid.height - 1 
    [x, y] 
  end


  # These methods detect when the buttons are clicked
  def animation_center_button_clicked?
    inputs.mouse.up && inputs.mouse.point.inside_rect?([500, 600, 200, 50])
  end

  def animation_right_button_clicked?
    inputs.mouse.up && inputs.mouse.point.inside_rect?([700, 600, 50, 50])
  end

  def animation_left_button_clicked?
    inputs.mouse.up && inputs.mouse.point.inside_rect?([450, 600, 50, 50])
  end

  # Signal that the user is going to be moving the slider
  def slider_clicked?
    inputs.mouse.down && inputs.mouse.point.inside_rect?([380 + state.anim_steps, 655, 37, 37])
  end

  # Signal that the user is going to be moving the star
  def star_clicked?
    inputs.mouse.down && inputs.mouse.point.inside_rect?([state.star.x * grid.tile_size, state.star.y * grid.tile_size, grid.tile_size, grid.tile_size])
  end

  # Signal that the user is going to be removing walls
  def wall_clicked?
    inputs.mouse.down && mouse_inside_a_wall?
  end

  # Signal that the user is going to be adding walls
  def grid_clicked?
    inputs.mouse.down && mouse_inside_grid?
  end

  # Returns whether the mouse is inside of a wall
  # Part of the condition that checks whether the user is removing a wall
  def mouse_inside_a_wall?
    state.walls.each_key do |x, y|
      return true if inputs.mouse.point.inside_rect?([x * grid.tile_size, y * grid.tile_size, grid.tile_size, grid.tile_size])
    end
    false
  end

  # Returns whether the mouse is inside of a grid
  # Part of the condition that checks whether the user is adding a wall
  def mouse_inside_grid?
    inputs.mouse.point.x >= 0 &&
      inputs.mouse.point.y >= 0 &&
      inputs.mouse.point.x < grid.width * grid.tile_size &&
      inputs.mouse.point.y < grid.height * grid.tile_size
  end

  # These methods provide handy aliases to colors
  def unvisited_color
    [221, 212, 213] # Light brown
  end

  def grid_line_color
    [255, 255, 255] # White
  end

  def visited_color
    [204, 191, 179] # Dark Brown
  end

  def frontier_color
    [103, 136, 204] # Blue
  end

  def wall_color
    [134, 134, 120] # Camo Green
  end

  # Grays are used in the buttons
  def light_gray
    [190, 190, 190]
  end

  def dark_gray
    [170, 170, 170]
  end


  # These methods make the code more concise
  def grid
    state.grid
  end

  def right_button
    state.right_button
  end

  def center_button
    state.center_button
  end

  def left_button
    state.left_button
  end
end


def tick args
  if args.inputs.keyboard.key_down.r
    args.gtk.reset
    reset
    return
  end

  $breadth_first_search ||= BreadthFirstSearch.new(args)
  $breadth_first_search.args = args
  $breadth_first_search.tick
end


def reset
  $breadth_first_search = nil
end
