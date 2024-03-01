#!/usr/bin/env ruby

require 'set'

# How many empty lines does there have to be?
THRESHOLD = 42

# Is this pixels section of the file?
pixels = false

# What is the code for white?
white = nil

# What's the current Y coord of the pixel?
y = 0

# What's the state of our scan?
state = :trail

# Y coord of current start of empty lines
start = nil

# Start of the current rectangle
rect_start = 0

# Overrides
breaks = Hash.new { |h,k| h[k] = Set.new(); h[k] }
breaks['022-l'] = Set.new([118])
breaks['026-l'] = Set.new([348])
breaks['028-l'] = Set.new([304, 395, 528, 665, 1032, 1175, 1307, 1720, 1954, 2086, 2229, 2407, 2545, 2870])
breaks['032-l'] = Set.new([530])
breaks['033-l'] = Set.new([713])
breaks['035-l'] = Set.new([711, 991])
breaks['037-r'] = Set.new([1083])
breaks['040-l'] = Set.new([117])
breaks['041-l'] = Set.new([988])
breaks['042-l'] = Set.new([2728])
breaks['046-r'] = Set.new([711])
breaks['048-r'] = Set.new([2776])
breaks['050-l'] = Set.new([442])
breaks['054-l'] = Set.new([2274])
breaks['057-l'] = Set.new([2500])
breaks['058-l'] = Set.new([1676])
breaks['063-r'] = Set.new([1630])
breaks['064-r'] = Set.new([1218])
breaks['065-r'] = Set.new([1360])
breaks['067-l'] = Set.new([2502])
breaks['069-r'] = Set.new([1310])
breaks['075-l'] = Set.new([1037, 1079])
breaks['077-l'] = Set.new([576])
breaks['080-l'] = Set.new([530])
breaks['081-l'] = Set.new([1636])
breaks['082-l'] = Set.new([346])
breaks['086-r'] = Set.new([71])
breaks['089-l'] = Set.new([2272])
breaks['090-l'] = Set.new([486, 574, 715])
breaks['090-r'] = Set.new([211])
breaks['093-l'] = Set.new([2640])

pfx = File.basename(ARGV.first, '.xpm')
File.readlines(ARGV.first).each do |l|
  # not in "pixels" section yet?
  if !pixels 
    if l =~ /"(\w+)\s+c\s+white"/
      white = $1
    end
    if l =~ /^\/\*\s+pixels\s+\*\/$/
      pixels = true
      next
    end
  end

  # we only want pixels here ...
  next unless pixels

  # skip trailing line
  break if pixels && l =~ /^};/

  # is the line empty?
  empty = l =~ /^"(#{white})+",?$/

  # is there an override?
  if breaks[pfx].include?(y)
    state = :overriden
    start = 0
  end
  
  # teh state machine
  case state
  when :trail
    state = :look if !empty
  when :look
    if empty
      state = :found
      start = y
    end
  when :found, :overriden
    if empty
      if y > start + THRESHOLD
	puts [rect_start, y].join(' ')
	rect_start = y
	state = :trail
      end
    else
      state = :look
    end
  end

  y += 1
end

# final summation...
puts [rect_start, y].join(' ') unless state == :trail
