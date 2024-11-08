require "./break_text"
require "./terminal"
require "./selectable_item"
require "./version"
require "./ext/option_parser"

require "term-screen"

class Selector
  @@terminal_width = -1
  @items : Array(SelectableItem)
  @current_index : Int32
  @delimiter : String
  @viewport_start : Int32
  @terminal_height : Int32
  @terminal_width : Int32
  @display_height : Int32

  def self.terminal_width
    @@terminal_width > -1 ? @@terminal_width : (@@terminal_width = determine_terminal_width)
  end

  def self.terminal_width=(value)
    @@terminal_width = value
  end

  def self.determine_terminal_width
    Term::Screen.size[1]
  end

  def initialize(args : Array(String), @delimiter : String = " ")
    @items = args.map { |arg| SelectableItem.new(arg) }
    @current_index = 0
    @viewport_start = 0
    @terminal_height, @terminal_width = Terminal.terminal_size

    # Leave one line at bottom for potential scroll indicator
    @display_height = @terminal_height - 1

    # Unescape the delimiter
    @delimiter = self.class.unescape_string(@delimiter)
  end

  def self.parse_setup
    # Parse command line options
    delimiter = " "
    input_delimiter = "\n"
    OptionParser.parse do |parser|
      parser.banner = <<-EHEREDOC
        Usage: selector [options] [items...]

        selector displays everything passed on the command line (other than valid arguments), as well as all lines that are passed on STDIN, on-screen with a simple text based UI to scroll through them, selecting some subset. The subset that is selected will be returned on STDOUT.

        Use the up and down arrows to move through the list.
        Press SPACE or 'x' to toggle the selected status of an item.
        Press 'q' to discard all selections and exit.
        Press ENTER to accept all selections.

      EHEREDOC

      parser.on("-d DELIMITER", "--delimiter=DELIMITER", "Specify output delimiter") do |_delimiter|
        delimiter = _delimiter
      end

      parser.on("-i DELIMITER", "--input-delimiter=DELIMITER", "Specify input delimiter for STDIN (default: newline)") do |_input_delimiter|
        input_delimiter = unescape_string(_input_delimiter)
      end

      parser.on("-v", "--version", "Show the selector version (v#{VERSION})") do
        puts "Version #{VERSION}"
        exit
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    # Get items from command line arguments
    items = ARGV.dup

    # Check if we have data on STDIN
    if !STDIN.tty?
      # Save the current STDIN
      stdin_content = STDIN.gets_to_end
      # Restore STDIN to the terminal
      STDIN.reopen(File.open("/dev/tty"))

      # Split STDIN content by delimiter and add non-empty items
      stdin_items = stdin_content.split(input_delimiter)
        .map(&.strip)
        .reject(&.empty?)

      items.concat(stdin_items)
    end

    if items.empty?
      puts "Error: No items provided"
      exit 1
    end

    {items, delimiter}
  end

  def run
    Terminal.clear_screen
    Terminal.hide_cursor
    Terminal.raw_mode

    begin
      loop do
        render
        handle_input
      end
    ensure
      Terminal.cooked_mode
      Terminal.show_cursor
    end
  end

  private def render
    Terminal.clear_screen

    # Calculate viewport end
    viewport_end = {@viewport_start + @display_height, @items.size}.min

    # Render visible items
    @items[@viewport_start...viewport_end].each_with_index do |item, index|
      Terminal.move_cursor(index + 1, 1)
      Terminal.clear_line
      STDERR.print item.to_s(@viewport_start + index == @current_index)
    end

    # Show scroll indicators if needed
    if @items.size > @display_height
      Terminal.move_cursor(@terminal_height, 1)
      Terminal.clear_line
      more_above = @viewport_start > 0
      more_below = viewport_end < @items.size
      status = String.build do |str|
        str << "#{more_above ? "▲ " : "  "}"
        str << "Showing #{@viewport_start + 1}-#{viewport_end} of #{@items.size}"
        str << "#{more_below ? " ▼" : "  "}"
      end
      STDERR.print status
    end

    STDOUT.flush
  end

  private def handle_input
    char = STDIN.read_char

    case char
    when '\e'
      # Handle arrow keys (escape sequences)
      if STDIN.read_char == '['
        case STDIN.read_char
        when 'A' # Up arrow
          move_cursor_up
        when 'B' # Down arrow
          move_cursor_down
        end
      end
    when ' ', 'x', 'X'
      @items[@current_index].selected = !@items[@current_index].selected?
    when '\r', '\n'
      # Exit and print selected items
      Terminal.cooked_mode
      Terminal.show_cursor
      Terminal.clear_screen
      selected_items = @items.select(&.selected?).map(&.text)
      print selected_items.join(@delimiter) # Use print instead of puts to handle custom delimiters properly
      exit
    when 'q', 'Q', '\u0003' # 'q', 'Q', or Ctrl+C
      Terminal.cooked_mode
      Terminal.show_cursor
      Terminal.clear_screen
      exit
    end
  end

  private def move_cursor_up
    if @current_index > 0
      @current_index -= 1
      # Scroll up if needed
      if @current_index < @viewport_start
        @viewport_start = @current_index
      end
    end
  end

  private def move_cursor_down
    if @current_index < @items.size - 1
      @current_index += 1
      # Scroll down if needed
      if @current_index >= @viewport_start + @display_height
        @viewport_start = @current_index - @display_height + 1
      end
    end
  end

  # Special character parsing helper
  # ameba:disable Metrics/CyclomaticComplexity
  def self.unescape_string(str : String) : String
    result = String.build do |str_build|
      i = 0
      while i < str.size
        if str[i] == '\\'
          if i + 1 >= str.size
            str_build << '\\'
            break
          end

          i += 1
          case str[i]
          when 'n'  then str_build << '\n'
          when 't'  then str_build << '\t'
          when 'r'  then str_build << '\r'
          when 'f'  then str_build << '\f'
          when 'v'  then str_build << '\v'
          when 'b'  then str_build << '\b'
          when 'a'  then str_build << '\a'
          when 'e'  then str_build << '\e'
          when '\\' then str_build << '\\'
          when '"'  then str_build << '"'
          when '\'' then str_build << '\''
          when 'x' # Hex escape
            if i + 2 < str.size
              hex = str[i + 1..i + 2]
              if hex =~ /^[0-9a-fA-F]{2}$/
                str_build << hex.to_i(16).chr
                i += 2
              else
                str_build << str[i]
              end
            else
              str_build << str[i]
            end
          when /[0-7]/ # Octal escape
            octal_digits = str[i..(i + 2).clamp(0, str.size - 1)].match(/^[0-7]{1,3}/).try(&.[0])
            if octal_digits
              str_build << octal_digits.to_i(8).chr
              i += octal_digits.size - 1
            else
              str_build << str[i]
            end
          else
            str_build << str[i]
          end
        else
          str_build << str[i]
        end
        i += 1
      end
    end
    result
  end
end
