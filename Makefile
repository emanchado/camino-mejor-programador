all: funcionales.html \
    consejospruebas.html \
    herramientas.html \
    malos_olores.html \
    documentacion_activa.html \
    calidad.html \
    integracion_continua.html \
    rest.html

%.html: %.asciidoc
	asciidoc $<

clean:
	rm *.html
	rm -rf tex-tmp
	rm book.tex
	rm -rf book.chunked book.pdf book.html book.epub

ARTICLE_SOURCE_FILES = funcionales.asc calidad.asc
SOURCE_FILES = book.asc $(ARTICLE_SOURCE_FILES)
XSLT_OPTS = --xsltproc-opts="--stringparam chapter.autolabel 0 --stringparam chunk.section.depth 0 --stringparam toc.section.depth 0"

libro: book.html book.epub book.chunked/index.html book.pdf

book.html: $(SOURCE_FILES)
	asciidoc -b html5 -a toc -a toclevels=1 book.asc

book.epub: $(SOURCE_FILES)
	a2x $(XSLT_OPTS) -f epub book.asc

book.chunked/index.html: book.xml
	a2x $(XSLT_OPTS) -f chunked book.xml
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
		sed -e 's/ñ/nn/g' book.tex >tmp.tex && \
		mv tmp.tex book.tex && \
		TEXINPUTS=/usr/share/dblatex/latex/style//::/etc/asciidoc/dblatex:/usr/share/dblatex/latex// pdflatex book.tex && \
		TEXINPUTS=/usr/share/dblatex/latex/style//::/etc/asciidoc/dblatex:/usr/share/dblatex/latex// pdflatex book.tex && \
		mv book.pdf ..

book.tex: $(SOURCE_FILES)
	a2x $(XSLT_OPTS) -f tex book.asc
	# Make the table of contents only have the article names
	sed 's/^\\setcounter{tocdepth}{[0-9]\+}/\\setcounter{tocdepth}{0}/' book.tex >book.tex-tmp
	# Add Javascript language definition rules for the "listings"
	# package. Thanks to Lena Herrmann for the tip:
	# http://lenaherrmann.net/2010/05/20/javascript-syntax-highlighting-in-the-latex-listings-package
	# Also, set secnumdepth to -1 so those pesky "Chapter X" are
	# not show at all
	sed 's/\\begin{document}/\\lstdefinelanguage{JavaScript}{keywords={typeof,new,true,false,catch,function,return,null,catch,switch,var,if,in,while,do,else,case,break},ndkeywords={class,export,boolean,throw,implements,import,this},sensitive=false,comment=[l]{\/\/},morecomment=[s]{\/*}{*\/},morestring=[b]'"'"',morestring=[b]"}\n\\setcounter{secnumdepth}{-1}\n\\renewcommand\\contentsname{\\'"'"'Indice}\n&/' book.tex-tmp >book.tex
	rm book.tex-tmp
