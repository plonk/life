#!/usr/bin/env ruby
require 'timeout'
require_relative 'tput'

class LifeGame
  # world dimensions
  WIDTH, HEIGHT = 160, 48
  OFFSET_TABLE = {
    'h' => [0, -1],
    'j' => [1, 0],
    'k' => [-1, 0],
    'l' => [0, 1],
    'y' => [-1, -1],
    'u' => [-1, 1],
    'b' => [1, -1],
    'n' => [1, 1]
  }

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

  # [ROW, COLUMNS]
  def get_screen_dimensions
    `stty size`.chomp.split.map(&:to_i)
  end

  # 右下の隅に空白を出力するとスクロールしてしまう端末用に最後の文字を削
  # 除したほうがいい？
  def show(origin_i, origin_j, stage)
    view_port = \
    (0...@screen_lines).map do |si|
      (0...@screen_columns).map do |sj|
        i = si + origin_i
        j = sj + origin_j

        if i >= 0 && i < HEIGHT && j >= 0 && j < WIDTH
          stage[i][j]
        else
          "X"
        end
      end.join
    end.join("\n")

    Tput.cursor_position(0, 0)
    STDOUT.write(view_port)

    Tput.cursor_position(0, 0)
    printf "Viewport: %dx%d%+d%+d", @screen_columns, @screen_lines, origin_j, origin_i
    STDOUT.flush
  end

  def load_stage(f)
    lines = f.each_line.map { |line| line.chomp }[0,HEIGHT]
    lines = lines.map { |line|
      line.gsub(/./) { |c| c=='*' ? '*' : ' '  }[0,WIDTH]
      line + ' ' * (WIDTH - line.size)
    }
    lines += [" "*WIDTH] * (HEIGHT - lines.size)
    lines.map { |line| [*line.each_char] }
  end

  def initialize
    @stage = case ARGV.size
             when 0
               load_stage(DATA)
             when 1..(Float::INFINITY)
               File.open(ARGV[0], "r") do |f|
                 load_stage(f)
               end
             else; fail
             end

    at_exit {
      STDOUT.write `tput rmcup` # back to primary screen
      system('stty sane')
    }

    STDOUT.write `tput smcup` # use alternate screen
    system('stty cbreak -echo')

    @origin_i, @origin_j = 0, 0

    @delay = 0.0166

    @screen_lines, @screen_columns = get_screen_dimensions
    Signal.trap(:SIGWINCH) {
      @screen_lines, @screen_columns = get_screen_dimensions
    }
  end

  def run
    commands = []
    loop do
      loop do
        begin
          Timeout.timeout(@delay) do
            commands << STDIN.getc
          end
        rescue Timeout::Error
          break
        end
      end

      # update screen dimensions
      # @screen_lines, @screen_columns = get_screen_dimensions

      commands.each do |c|
        case c
        when 'h', 'j', 'k', 'l', 'y', 'u', 'b', 'n'
          @origin_i += OFFSET_TABLE[c][0]
          @origin_j += OFFSET_TABLE[c][1]
        when 'q'
          return
        end
      end
      commands.clear

      show(@origin_i, @origin_j, @stage)
      @stage = step(@stage)
      sleep 0.0166
    end
  end

end

LifeGame.new.run

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
