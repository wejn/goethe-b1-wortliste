#!/bin/bash

F=Goethe-Zertifikat_B1_Wortliste.pdf
P=$1

if test ! -f "Goethe-Zertifikat_B1_Wortliste-$P.png"; then
  echo "Page $P doesn't exist." >&2
  exit 1
fi

# Y ranges
if [ ! -f $P-l.txt -o ! -f $P-r.txt ]; then
  echo "$P: Figuring out ranges..."

  convert Goethe-Zertifikat_B1_Wortliste-$P.png -crop $[1200-140]x$[3260-320]+140+320 $P-l.xpm
  convert Goethe-Zertifikat_B1_Wortliste-$P.png -crop $[2340-1300]x$[3260-320]+1300+320 $P-r.xpm

  ruby detect-breaks.rb $P-l.xpm > $P-l.txt
  ruby detect-breaks.rb $P-r.xpm > $P-r.txt
  rm -f $P-l.xpm $P-r.xpm
fi

# annotation
if [ ! -f $P-annot.png ]; then
  echo "$P: Annotation..."

  cp Goethe-Zertifikat_B1_Wortliste-$P.png $P-annot.png
  cat $P-l.txt | ruby annotate.rb $P-annot.png 140 1200 320
  cat $P-r.txt | ruby annotate.rb $P-annot.png 1300 2340 320
fi

# extraction
if [ ! -f $P-r.msh -o ! -f $P-l.msh ]; then
  echo "$P: Extraction..."

  ruby extract.rb "$F" $P $P-l.txt 140 540 1200 320 l
  ruby extract.rb "$F" $P $P-r.txt 1300 1710 2340 320 r
fi

# generation
if [ ! -f $P.html -o ! -f $P.csv ]; then
  echo "$P: Generation..."

  ruby generate.rb $P
fi
