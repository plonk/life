module Tput
  def cursor_position(row, col)
    system("tput cup #{row} #{col}")
  end
  module_function :cursor_position

  def cursor_invisible
    system("tput civis")
  end
  module_function :cursor_invisible

  def clear
    system("tput clear")
  end
  module_function :clear

  def reset
    system("tput reset")
  end
  module_function :reset

end
