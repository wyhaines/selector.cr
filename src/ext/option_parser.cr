require "option_parser"

# These modifications to OptionParser apply text wrapping so that the command-line help is
# nicely formatted regardless of terminal width, and so that the formatting is visually
# similar to the Javascript version.
class OptionParser
  def to_s(io : IO) : Nil
    # Get the width of the screen so that text can be intelligently wrapped.

    if banner = @banner
      io << Selector.break_text(banner.to_s, Selector.terminal_width)
      io << '\n'
    end
    @flags.join io, '\n'
  end

  private def append_flag(flag, description)
    indent = " " * 31
    description = description.gsub("\n", "\n#{indent}")
    if flag.size >= 27
      @flags << "    #{flag}\n#{Selector.break_text(indent + description, Selector.terminal_width)}"
    else
      @flags << "    #{flag}#{Selector.break_text(indent + description, Selector.terminal_width)[4 + flag.size..]}"
    end
  end

  def separator(message = "")
    @flags << Selector.break_text(message.to_s, Selector.terminal_width)
  end
end
