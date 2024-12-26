#!/bin/bash
# This script converts a Word document to a LaTeX document
# Export the vars in .env into your shell:
DOCX=$(grep DOCX $1 | xargs)
BIBLIO=$(grep BIBLIO $1 | xargs)
LATEXFOLDER=$(grep LATEXFOLDER $1 | xargs)
CITETAG=$(grep CITETAG $1 | xargs)
PANDOCPATH=$(grep PANDOCPATH $1 | xargs)


# ASSIGN VARIABLES
TEMPLATEX="/tmp/latex"
CURRENT_DIR=`pwd`

# for github actions
[ -d "$LATEXFOLDER" ] && cd "$LATEXFOLDER"
[ -d /workdir ] && cd /workdir

# Remove XX= prefix - https://stackoverflow.com/questions/16623835/remove-a-fixed-prefix-suffix-from-a-string-in-bash
DOCX=${DOCX#"DOCX="}
BIBLIO=${BIBLIO#"BIBLIO="}
LATEXFOLDER=${LATEXFOLDER#"LATEXFOLDER="}
CITETAG=${CITETAG#"CITETAG="}
PANDOCPATH=${PANDOCPATH#"PANDOCPATH="}


rm /tmp/latex-files-*
[ ! -d "$LATEXFOLDER/paperaj" ] && mkdir "$LATEXFOLDER/paperaj"

# Extract media
"${PANDOCPATH}pandoc" --extract-media $LATEXFOLDER/ -i "$DOCX" -s --bibliography="$BIBLIO" --wrap=preserve --csl=word2latex-pandoc.csl -o /tmp/latex-files-temp-1.md

# Adds abstract
"${PANDOCPATH}pandoc" -i "$DOCX" -s --bibliography="$BIBLIO" --wrap=preserve --csl=word2latex-pandoc.csl -o /tmp/latex-files-temp-1.md
python metadata.py /tmp/latex-files-temp-1.md /tmp/latex-files-temp-1m.md "$LATEXFOLDER/paperaj/title.tex" "$LATEXFOLDER/paperaj/author.tex"
"${PANDOCPATH}pandoc" -i /tmp/latex-files-temp-1m.md -o "$LATEXFOLDER/paperaj/abstract.tex"

sed -e 's/!\[\](media/!\[image\](media/g' /tmp/latex-files-temp-1.md > /tmp/latex-files-temp-11.md
"${PANDOCPATH}pandoc" -i /tmp/latex-files-temp-11.md --bibliography="$BIBLIO" --wrap=auto --columns=140 --csl=word2latex-pandoc.csl -o /tmp/latex-files-temp-2.tex
echo "Conversion Complete"

cat /tmp/latex-files-temp-2.tex | sed -e 's/\\hypertarget{.*}{\%//g' > /tmp/latex-files-temp-5.tex
cat /tmp/latex-files-temp-5.tex | sed -e 's/\\label{.*}//g' > /tmp/latex-files-temp-6a.tex
if [ "$CITETAG" != "citep" ]
then
    cat /tmp/latex-files-temp-6a.tex | sed -e 's/\\textbackslash.*cite\\{/\\cite{/g' > /tmp/latex-files-temp-6b.tex
else
    cat /tmp/latex-files-temp-6a.tex | sed -e 's/\\textbackslash.*cite\\{/\\citep{/g' > /tmp/latex-files-temp-6b.tex
fi
cat /tmp/latex-files-temp-6b.tex | sed -e 's/\\textbackslash.*citet\\{/\\citet{/g' > /tmp/latex-files-temp-6.tex

# Remove line breaks added on 3/21/2021
awk ' /^\\/ { printf("%s \n", $0); } /^$/ { print "\n"; }  /^[^\\].*/ { printf("%s ", $0); } END { print ""; } ' /tmp/latex-files-temp-6.tex > /tmp/latex-files-temp-6c.tex
python images.py /tmp/latex-files-temp-6c.tex /tmp/latex-files-temp-7.tex

# Split file into section chapters. Last one will be references
csplit -k -f /tmp/latex-files- /tmp/latex-files-temp-7.tex '/\\section{\\texorpdfstring{\\emph{/' '{15}'
for i in {0..15} # upto 15 sections
do
    size=${#i}
    if [ $size == 1 ]
    then
        i="0${i}"  # the format is latex-files-0x. 0 added for i has onle one digit
    fi
    echo "Handling section: $i"
    if test -f "/tmp/latex-files-$i"; then
        # second part removes the session breat ie H1 header in italics
        cat /tmp/latex-files-$i | sed -e '1,2d' | sed -e 's/\\section{\\texorpdfstring{\\emph{.*//g' > /tmp/latex-files-$ia
        cp /tmp/latex-files-$ia "$LATEXFOLDER/paperaj/chapter-$i.tex"
    fi
done

## Copy files
[ -d "$BIBLIO" ] && cp "$BIBLIO" "$LATEXFOLDER"
cp "$BIBLIO" "$LATEXFOLDER/references.bib"


echo "Processing complete"

