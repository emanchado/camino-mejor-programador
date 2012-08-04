all: herramientas.html \
    malos_olores.html \
    eclipse.html \
    rest.html \
    tdd.html

%.html: %.asciidoc
	asciidoc $<

clean:
	rm *.html
	rm -rf tex-tmp epub-tmp
	rm book.tex book.xml
	rm -rf book.chunked book.pdf book.html book.epub

ARTICLE_SOURCE_FILES = funcionales documentacion_activa consejospruebas calidad integracion_continua
SOURCE_FILES = book.asc $(foreach article,$(ARTICLE_SOURCE_FILES),$(article).asc $(article)-biblio.asc)
XSLT_OPTS = --xsltproc-opts="--stringparam chapter.autolabel 0 --stringparam chunk.section.depth 0 --stringparam toc.section.depth 0"

libro: book.html book.epub book.chunked/index.html book.pdf

book.asc: book.asc.in Makefile
	sed -n '/#ARTICLELIST#/,$$ !p' book.asc.in >book.asc
	for i in $(ARTICLE_SOURCE_FILES); do \
		echo "include::$$i.asc[]\n" >>book.asc; \
	done
	sed -e '1,/#ARTICLELIST#/d' -e '/#BIBLIOLIST#/d' book.asc.in >>book.asc
	for i in $(ARTICLE_SOURCE_FILES); do \
		echo "include::$$i-biblio.asc[]\n" >>book.asc; \
	done
	sed -e '1,/#BIBLIOLIST#/d' book.asc.in >>book.asc

book.html: $(SOURCE_FILES)
	asciidoc -b html5 -a toc -a toclevels=1 book.asc

book.epub: book.xml libro.css
	a2x $(XSLT_OPTS) -f epub --stylesheet libro.css book.xml
	rm -rf epub-tmp
	mkdir epub-tmp && cd epub-tmp && unzip ../book.epub
	for i in epub-tmp/OEBPS/ch*.html; do \
		xmllint -format $$i >$$i.tmp; \
		./fix-highlighting.py $$i.tmp >$$i; \
		rm $$i.tmp; \
	done
	./fix-epub-toc.py epub-tmp/OEBPS/toc.ncx >epub-tmp/toc.ncx && mv epub-tmp/toc.ncx epub-tmp/OEBPS/toc.ncx
	cd epub-tmp && rm -f ../book.epub && zip -r ../book.epub *

book.chunked/index.html: book.xml libro.css
	a2x $(XSLT_OPTS) -f chunked --stylesheet libro.css book.xml
	for i in book.chunked/ch*.html; do \
		xmllint -format $$i >$$i.tmp; \
		./fix-highlighting.py $$i.tmp >$$i; \
		rm $$i.tmp; \
	done

book.xml: $(SOURCE_FILES)
	asciidoc -b docbook book.asc
	sed 's/<programlisting language="\([^"]*\)"[^>]*>/&LANGUAGE=\1 /' book.xml >tmp.xml && mv tmp.xml book.xml

book.pdf: book.tex
	rm -rf tex-tmp
	mkdir tex-tmp
	cat $< >tex-tmp/book.tex
	cd tex-tmp && \
		sed 's/[áéíóúñ]/_/gi' book.tex >tmp.tex && \
		mv tmp.tex book.tex && \
		TEXINPUTS=/usr/share/dblatex/latex/style//::/etc/asciidoc/dblatex:/usr/share/dblatex/latex// pdflatex book.tex && \
		TEXINPUTS=/usr/share/dblatex/latex/style//::/etc/asciidoc/dblatex:/usr/share/dblatex/latex// pdflatex book.tex && \
		pdftk book.pdf cat 3-end output ../book.pdf

book.tex: $(SOURCE_FILES)
	a2x $(XSLT_OPTS) -f tex book.asc
	# Specify that the document language in Spanish (for hyphenation rules)
	sed 's/^\\documentclass{report}/&\n\\usepackage[spanish]{babel}/' book.tex >book.tex-tmp && mv book.tex-tmp book.tex
	# Make the table of contents only have the article names
	sed 's/^\\setcounter{tocdepth}{[0-9]\+}/\\setcounter{tocdepth}{0}/' book.tex >book.tex-tmp && mv book.tex-tmp book.tex
	# Add Javascript language definition rules for the "listings"
	# package. Thanks to Lena Herrmann for the tip:
	# http://lenaherrmann.net/2010/05/20/javascript-syntax-highlighting-in-the-latex-listings-package
	# Also, set secnumdepth to -1 so those pesky "Chapter X" are
	# not show at all
	sed 's/\\begin{document}/\\lstdefinelanguage{JavaScript}{keywords={typeof,new,true,false,catch,function,return,null,catch,switch,var,if,in,while,do,else,case,break},ndkeywords={class,export,boolean,throw,implements,import,this},sensitive=false,comment=[l]{\/\/},morecomment=[s]{\/*}{*\/},morestring=[b]'"'"',morestring=[b]"}\n\\setcounter{secnumdepth}{-1}\n\\renewcommand\\contentsname{\\'"'"'Indice}\n&/' book.tex >book.tex-tmp && mv book.tex-tmp book.tex
