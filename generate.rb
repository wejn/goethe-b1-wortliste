#!/usr/bin/env ruby

require 'csv'
require 'pp'

def process(input, buf)
  input.each do |(i, d, e)|
    if d == "" && buf[-1]
      p = buf[-1]
      p[0] = [p[0], i].flatten
      p[2] = p[2] + "\n" + e
    else
      buf << [i, d, e]
    end
  end
  buf
end

page = ARGV.first
input_data = []
Array(page == "all" ? ("016".."102") : page).each do |pn|
  process(Marshal.load(File.read(pn + "-l.msh")), input_data)
  process(Marshal.load(File.read(pn + "-r.msh")), input_data)
end

csv_data = []
html_data = []
for img, d, e in input_data
  # fix broken lists (item numbers in front)
  if e =~ /\A(([0-9]\.\n)+)\n/m
    m = $1
    msz = m.split(/\n/).size
    e = e[(m.size+1)..-1]
    e = e.split(/\n/)
    e = e[0, msz].inject([[], 1]) { |(o,i),x| [o + ["#{i}. #{x}"], i+1] }.
      first + e[msz..-1]
    e = e.join("\n")
  end

  # fix up newlines in examples
  if e =~ /\A(\d+)\./
    start = $1.to_i
    # list
    e = e.split(/^\d{1,2}\.\s*/)[1..-1].map { |x| x.strip.tr("\n", " ") }.
      inject([[], start]) { |(o,i),x| [o + ["#{i}. #{x}"], i+1] }.
      first.join("\n")
  else
    # sentence
    e = e.tr("\n", " ")
  end

  # Cosmetic fixes to explanations
  e = e.sub(/Ding\? Damit/, 'Ding? - Damit') # p30
  e = e.sub(/Müller ist\? Nein/, 'Müller ist? - Nein') # p38

  # fix newlines in defs
  if d =~ /\Ader.*die/m
    d = d.gsub(/\nd(er|ie)/, "~d\\1").tr("\n", " ").
      gsub(/~d(er|ie)/, "\nd\\1")
  else
    d = d.tr("\n", " ")
  end

  # Fix up "der W, die Win, ..." -> "der W, -\ndie Win, ..."
  d = d.sub(/\Ader (.+?), die (.+?),\s+(.*?)(\s|\z)/,
	    "der \\1, -\ndie \\2, \\3 ")

  # Fix up nouns with "der ... / die ..."
  d = d.gsub(/\A(der\s+.*?)\s+\/\s+(die\s+.*?)/, "\\1\n\\2")

  # Fix up " → " -> "\n→ "
  d = d.gsub(/\)→([ADC])/, ") → \\1").gsub(/\)→\s+/, ")\n→ ").
    gsub(/\s+→\s+/, "\n→ ")

  # Fix up "(A)" alone on line
  d = d.gsub(/\n\s*(\((A|D|CH)(,\s+(A|D|CH))*\))\s*$/, " \\1")

  # Strip trailing spaces
  d.strip!

  # Ignore empty examples (e.g. p. 75 rück-)
  next if e.empty?

  # Cosmetic touch-up for Hausfrau/Hausmann (p. 49)
  if d =~ /Hausfrau.*Hausmann/ && e =~ /Hausfrau.*kümmert.*Hausmann.*kümmert/
    d = d.tr('/', "\n")
    e = e.tr('/', "\n")
  end

  # Cosmetic touch-ups for a few things
  d = d.sub(/raus\(heraus/, 'raus- (heraus') # p49
  d = d.sub(/runter\(herunter/, 'runter- (herunter') # p49
  d = d.sub(/Kriminaldie Krimi/, "Kriminal-\ndie Krimi") # p57
  d = d.sub(/Reception, en/, 'Reception, -en') # p74
  d = d.sub(/Serviceangestellte, n /, 'Serviceangestellte, -n ') # p80
  d = d.sub(/überübertreiben,/, "über-\nübertreiben,") # p89

  # scanning for mistakes... TODO: remove later
  #next if e =~ /\A1\./
  #next unless e.scan(".").size > 1
  #next unless e =~ / 1\..*2\./

  csv_data << [d, e]

  # don't generate images in HTML anymore...
  if false
    html_data << "<tr><td colspan=\"2\">"
    Array(img).each do |i|
      html_data << "<img src=\"#{i}\" width=\"500\" /><br />"
    end
    html_data << "</td></tr>"
  end

  html_data << "<tr><td>#{d.gsub(/\n/,"<br />\n")}</td>" + 
    "<td>#{e.gsub(/\n/,"<br />\n")}</td></tr>"
end

File.open("#{page}.html", "w") do |html|
  html.puts '<!DOCTYPE html>'
  html.puts '<html lang="de">'
  html.puts "<head>"
  html.puts '<meta charset="UTF-8" />'
  html.puts '<meta name="viewport" content="width=device-width" />'
  if page == "all"
    html.puts "<title>Pages 16..102 :: Goethe Zertifikat B1 Wortliste</title>"
  else
    html.puts "<title>Page #{page.to_i(10)} :: Goethe Zertifikat B1 Wortliste</title>"
  end
  html.puts <<'EOF'
<style>
      table { border: 2px solid black; border-collapse: collapse; }
      table th { border: 1px solid #aaa; padding: 0.2em 0.5em; }
      table th:not([colspan]) { border-bottom: 2px solid black; }
      table td { text-align: left; border: 1px solid #aaa; padding: 0.2em 0.5em; }
      p { max-width: 800px; }
    </style>
</head>
EOF
  html.puts "</head>"
  html.puts "<body>"
  html.puts "<h1>Goethe Zertifikat B1 Wortliste</h1>"
  html.puts <<-'EOF'
<p>
All of this text is extracted from
<a href="https://www.goethe.de/pro/relaunch/prf/de/Goethe-Zertifikat_B1_Wortliste.pdf">Goethe-Zertifikat_B1_Wortliste.pdf</a>
(© 2016 Goethe-Institut und ÖSD)
because their PDF was unusable for making flashcards.
</p>
<p>
I elaborated on <a href="https://wejn.org/2023/12/extracting-data-from-goethe-zertifikat-b1-wortliste/">the extraction process</a>
on my blog.
</p>
<p>
It is highly likely you can use this for personal purposes, but I make no claim
that I own the resulting data. In other words: if I were you, I wouldn't go
using this in any commercial capacity.
</p>
  EOF
  if page == "all"
    html.puts "<h2>Pages 16..102</h2>"
  else
    html.puts "<h2>Page #{page.to_i(10)}</h2>"
  end
  html.puts "<table>"
  html.puts "<tr><th>Def</th><th>Example</th></tr>"
  html.puts html_data
  if page != "all"
    html.puts "<tr>"
    pr = "%03d" % (page.to_i(10)-1)
    ne = "%03d" % (page.to_i(10)+1)
    if page.to_i(10) == 16
      html.puts "<th>&nbsp;</th>"
    else
      html.puts "<th><a href=\"#{pr}.html\">page #{pr}</a></th>"
    end
    if page.to_i(10) == 102
      html.puts "<th>&nbsp;</th>"
    else
      html.puts "<th><a href=\"#{ne}.html\">page #{ne}</a></th>"
    end
    html.puts "</tr>"
  end
  html.puts "</table>"
  html.puts "</body>"
  html.puts "</html>"
end

File.open("#{page}.csv", "w") do |c|
  c.write(CSV.generate_lines(csv_data))
end
