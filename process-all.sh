#!/bin/bash

set -e

if test ! -f Goethe-Zertifikat_B1_Wortliste.pdf; then
  echo "Get yourself Goethe-Zertifikat_B1_Wortliste.pdf"
  echo "It used to live at https://www.goethe.de/pro/relaunch/prf/de/Goethe-Zertifikat_B1_Wortliste.pdf"
  exit 1
fi

if test ! -f Goethe-Zertifikat_B1_Wortliste-104.png; then
  echo "Extracting PNGs..."
  pdftocairo -png -r 300 Goethe-Zertifikat_B1_Wortliste.pdf
fi

echo "Processing pages..."
for i in $(seq -w 16 102); do
  echo $i...
  ./process-page.sh $i
done

echo "Generating final file..."
ruby generate.rb all
