#!/usr/bin/env ruby

if ARGV.size != 4
  STDERR.puts "Usage: #{File.basename($0)} <f> <x0> <x1> <y>"
  exit 1
end

f = ARGV.first
x0, x1, y = *ARGV[1,3].map(&:to_i)

coords = []
STDIN.each do |ln|
  coords << ln.split(/\s+/,2).map(&:to_i)
end

cmd = ["convert", f, "-fill", "transparent", "-stroke", "red"]
for y0, y1 in coords
  cmd += ["-draw", "rectangle #{x0},#{y+y0} #{x1},#{y+y1}"]
end
cmd << f
system *cmd
