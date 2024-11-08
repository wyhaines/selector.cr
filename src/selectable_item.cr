# Represents a selectable item in the list
class SelectableItem
  property text : String
  property? selected : Bool

  def initialize(@text, @selected = false)
  end

  def to_s(is_current : Bool) : String
    checkbox = selected? ? "[x]" : "[ ]"
    highlight = is_current ? "\e[7m" : "" # Inverse video for current item
    reset = is_current ? "\e[0m" : ""
    "#{highlight}#{checkbox} #{text}#{reset}"
  end
end
