#!/usr/bin/env ruby

if ARGV.size != 8
  STDERR.puts "Usage: #{File.basename($0)} <pdf> <page> <yranges> <x0> <x1> <x2> <y> <col>"
  exit 1
end

pdf = ARGV.first
page = ARGV[1]
coords = []
File.readlines(ARGV[2]).each do |ln|
  coords << ln.split(/\s+/,2).map(&:to_i)
end
x0, x1, x2, y = ARGV[3,4].map(&:to_i)
col = ARGV[7]

outfile = "#{page}-#{col}.msh"

exit 0 if FileTest.file?(outfile)

out = []

coords.each_with_index do |(y0, y1), idx|
  i, l, r = nil
  i = "#{page}-#{col}-#{idx}.png"
  unless FileTest.file?(i)
    system(*["convert", "Goethe-Zertifikat_B1_Wortliste-#{page}.png",
	     "-crop", "#{x2-x0}x#{y1-y0}+#{x0}+#{y+y0}", "+repage", i])
  end
  IO.popen(["pdftotext", "-f", page, "-l", page, "-r", 300,
	    "-x", x0, "-y", y+y0, "-W", x1-x0, "-H", y1-y0,
	    pdf, "-"].map(&:to_s), 'r') do |f|
    l = f.read.strip
  end
  IO.popen(["pdftotext", "-f", page, "-l", page, "-r", 300,
	    "-x", x1, "-y", y+y0, "-W", x2-x1, "-H", y1-y0,
	    pdf, "-"].map(&:to_s), 'r') do |f|
    r = f.read.strip
  end

  # Fix up broken left column of page 079, sigh
  if page == "079" && col == "l"
    if l =~ /^die See.*die Nord.*Ostsee/m && r =~ /Im Sommer/
      l = "die See"
      r = "Im Sommer fahren wir immer an die See."
    elsif l =~ /^sehen,/ && r =~ /Warst du schon/
      l = "die Nord-/Ostsee"
      r = "Warst du schon mal an der Nord/Ostsee?"
    elsif l == "" && r =~ /^1\.\s+Ich\s+sehe\s+nicht/
      l = "sehen, sieht, sah, hat gesehen"
    end
  end

  out << [i, l, r]
end

File.open(outfile, "w") { |f| Marshal.dump(out, f) }
