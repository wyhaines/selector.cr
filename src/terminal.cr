# This provides an absolutely minimal set of terminal functions.
module Terminal
  extend self

  def raw_mode
    system("stty raw -echo")
  end

  def cooked_mode
    system("stty -raw echo")
  end

  def clear_screen
    STDERR.print "\e[2J\e[H"
  end

  def move_cursor(row : Int32, col : Int32)
    STDERR.print "\e[#{row};#{col}H"
  end

  def clear_line
    STDERR.print "\e[2K"
  end

  def hide_cursor
    STDERR.print "\e[?25l"
  end

  def show_cursor
    STDERR.print "\e[?25h"
  end

  def terminal_size
    if height_str = `tput lines`.strip
      height = height_str.to_i
    else
      height = 24 # fallback
    end

    if width_str = `tput cols`.strip
      width = width_str.to_i
    else
      width = 80 # fallback
    end

    {height, width}
  end
end
