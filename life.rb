#!/usr/bin/env ruby
require_relative 'tput'

def step(stage)
  height, width = stage.size, stage.first.size
  surrounding = [[-1,0],[-1,1],[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1]]

  neighbours = proc { |i,j|
    surrounding.each_with_object([]) do |(di, dj), res|
      i_ = i + di
      j_ = j + dj
      if i_ >= 0 && i_ < height && j_ >= 0 && j_ < width
        res << [i_, j_]
      end
    end
  }

  char_at = proc { |i,j| stage[i][j] }

  next_char = proc { |i,j|
    neighbour_count = neighbours.(i,j).map(&char_at).count("*")
    case stage[i][j]
    when ' ' # dead cell
      case neighbour_count
      when 3
        '*'
      else
        ' '
      end
    when '*' # live cell
      case neighbour_count
      when 0..1
        ' ' # underpopulation
      when 2..3
        '*'
      when 4..8
        ' ' # overpopulation
      end
    end
  }

  stage.map.with_index { |row, i|
    row.map.with_index { |_cell, j|
      next_char.(i, j)
    }
  }
end

# 右下の隅に空白を出力するとスクロールしてしまう端末用に最後の文字を削
# 除したほうがいい？
def show(stage)
  print stage.map { |row| row.join }.join("\n")
  STDOUT.flush
end

def load_stage(f)
  lines = f.each_line.map { |line| line.chomp }[0,24]
  lines = lines.map { |line|
    line.gsub(/./) { |c| c=='*' ? '*' : ' '  }[0,80]
    line + ' ' * (80 - line.size)
  }
  lines += [" "*80] * (24 - lines.size)
  lines.map { |line| [*line.each_char] }
end

stage = if ARGV.size > 0
          File.open(ARGV[0], "r") do |f|
            load_stage(f)
          end
        else
          load_stage(DATA)
        end

at_exit {
  Tput.reset
}

Tput.cursor_invisible

loop do
  Tput.clear
  show(stage)
  stage = step(stage)
  sleep 0.0166
end

__END__

                                           ******
                                           *********                  ***
                                           *********                     ***
                                        ***************         ***      ***
                                     ***   ************            ***   ******
                               ******      ************      ***   ***      ***
                            ***         ***   *********               ***   ***
                         ***            ***   *********         ***   ***   ***
                   ******               ***   ************      ***   ***   ***
          ************                  ***      *********      ***   ***   ***
          ************                     ***   *********      ***   ***   ***
 ***   ***************                     ***   *********      ***   ***   ***
 ***   ***************                        ************                  ***
 ***   ***************                        ************
    *********************************         ************
             ************            ******************
                *********                           ***
                   ******
                   *********
                   *********
                   *********
                      ******
