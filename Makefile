ARTICLE_SOURCE_FILES = funcionales documentacion_activa consejospruebas calidad integracion_continua tdd
SOURCE_FILES = book.asc $(foreach article,$(ARTICLE_SOURCE_FILES),$(article).asc $(article)-biblio.asc)
XSLT_OPTS = --xsltproc-opts="--stringparam chapter.autolabel 0 --stringparam chunk.section.depth 0 --stringparam toc.section.depth 0"
BUILD_ID = $(shell git log -1 --format='Committed %ci %H')
BUILD_LINK = $(shell git log -1 --format='<a href="https://www.assembla.com/code/proyecto-libro/git/changesets/%H">Versión %ci %h</a>')
BUILD_ID_URL = $(shell git log -1 --format='https://www.assembla.com/code/proyecto-libro/git/changesets/%H')

#COMMIT_DATE_TIME = $(shell date --date="`git log -1 --format='%ci'`" --utc '+%Y%m%dT%H%M%S')
#FILENAME = $(shell git log -1 --format='camino-$(COMMIT_DATE_TIME)-%h')
#COMMIT_DATE_TIME = $(shell git log -1 --format='%ci' | sed 's/ /_/g' | sed 's/:/^/g')
#FILENAME = $(shell git log -1 --format='camino_$(COMMIT_DATE_TIME)_%h')
COMMIT_DATE_TIME = $(shell date --date="`git log -1 --format='%ci'`" --utc '+%Y-%m-%d')
FILENAME = $(shell git log -1 --format='camino_$(COMMIT_DATE_TIME)_%h')

libro: html epub chunked pdf


html: $(FILENAME).html
	#cp $(FILENAME).html `echo $(FILENAME) | sed 's/\^/:/g'`.html

epub: $(FILENAME).epub 
	#cp $(FILENAME).epub `echo $(FILENAME) | sed 's/\^/:/g'`.epub

chunked: $(FILENAME).chunked/index.html
	#cp -R $(FILENAME).chunked `echo $(FILENAME) | sed 's/\^/:/g'`.chunked

pdf: $(FILENAME).pdf
	#cp $(FILENAME).pdf `echo $(FILENAME) | sed 's/\^/:/g'`.pdf

.PHONY: html epub chunked pdf

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
	sed 's/#BUILDID#/$(BUILD_ID)/' book.asc >book.asc-tmp && mv book.asc-tmp book.asc

$(FILENAME).html: $(SOURCE_FILES)
	asciidoc -b html5 -a toc -a toclevels=1 -a themedir=`pwd`/theme-libro --theme=libro book.asc
	# Build id
	sed 's|^Last updated.*|$(BUILD_LINK)|' book.html >book.html-tmp && mv book.html-tmp book.html
	# Fix generation of dashes next to words (with no space in between)
	sed -e 's/ --\([^ ->]\)/ \&#8212;\1/g' -e 's/\([^<][^ -]\)--\([ ,\.:;)(]\)/\1\&#8212;\2/' book.html >book.html-tmp && \
		./single-html-listing-title-hack.pl book.html-tmp >book.html && \
		rm book.html-tmp
	mv book.html $(FILENAME).html

$(FILENAME).epub: book.xml libro.css
	a2x $(XSLT_OPTS) -f epub --stylesheet libro.css book.xml
	rm -rf epub-tmp
	mkdir epub-tmp && cd epub-tmp && unzip ../book.epub
	for i in epub-tmp/OEBPS/ch*.html; do \
		xmllint -format $$i >$$i.tmp; \
		./fix-highlighting.py $$i.tmp >$$i; \
		./chunked-html-listing-title-hack.pl $$i >$$i.tmp; \
		mv $$i.tmp $$i; \
	done
	./fix-epub-toc.py epub-tmp/OEBPS/toc.ncx >epub-tmp/toc.ncx && mv epub-tmp/toc.ncx epub-tmp/OEBPS/toc.ncx
	./add-epub-cover.sh epub-tmp/OEBPS/content.opf >epub-tmp/content.opf && mv epub-tmp/content.opf epub-tmp/OEBPS/content.opf
	cp cover.html epub-tmp/OEBPS
	cp cover.png epub-tmp/OEBPS
	cd epub-tmp && rm -f ../book.epub && zip -r ../$(FILENAME).epub *

$(FILENAME).chunked/index.html: book.xml libro.css
	cp book.xml $(FILENAME).xml
	a2x $(XSLT_OPTS) -f chunked --stylesheet libro.css $(FILENAME).xml
	for i in $(FILENAME).chunked/ch*.html; do \
		xmllint -format $$i >$$i.tmp; \
		./fix-highlighting.py $$i.tmp >$$i; \
		./chunked-html-listing-title-hack.pl $$i >$$i.tmp; \
		mv $$i.tmp $$i; \
	done

book.xml: $(SOURCE_FILES)
	asciidoc -b docbook book.asc
	sed 's/<programlisting language="\([^"]*\)"[^>]*>/&LANGUAGE=\1 /' book.xml >tmp.xml && mv tmp.xml book.xml

cover.pdf: cover.png
	convert $< $@

$(FILENAME).pdf: book.tex cover.pdf
	rm -rf tex-tmp
	mkdir tex-tmp
	cat $< >tex-tmp/book.tex
	convert cc-by-sa-big.png tex-tmp/cc-by-sa.pdf
	cd tex-tmp && \
		sed -e 's/[áéíóúñ]/_/gi' -e 's/cc-by-sa.png/cc-by-sa.pdf/g' book.tex >tmp.tex && \
	        ../tex-listing-title-hack.pl tmp.tex >book.tex && \
		TEXINPUTS=/usr/share/dblatex/latex/style//::/etc/asciidoc/dblatex:/usr/share/dblatex/latex// pdflatex book.tex && \
		TEXINPUTS=/usr/share/dblatex/latex/style//::/etc/asciidoc/dblatex:/usr/share/dblatex/latex// pdflatex book.tex && \
		pdftk C=../cover.pdf B=book.pdf cat C B3-end output book-with-cover.pdf keep_final_id && \
		../set_pdf_metadata.bash <book-with-cover.pdf >../$(FILENAME).pdf 'El camino a un mejor programador' 'Varios Autores' $(BUILD_ID_URL)

book.tex: $(SOURCE_FILES)
	a2x -a lang=es $(XSLT_OPTS) -f tex book.asc
	# Make the table of contents only have the article names
	sed 's/^\\setcounter{tocdepth}{[0-9]\+}/\\setcounter{tocdepth}{0}/' book.tex >book.tex-tmp && mv book.tex-tmp book.tex
	# Add Javascript and Scala language definition rules for the
	# "listings" package. Thanks to Lena Herrmann and Mark/Eivind
	# for the tip:
	# http://lenaherrmann.net/2010/05/20/javascript-syntax-highlighting-in-the-latex-listings-package
	# http://tex.stackexchange.com/questions/47175/scala-support-in-listings-package / http://tihlde.org/~eivindw/
	# Also, set secnumdepth to -1 so
	# those pesky "Chapter X" are not show at all
	sed 's/\\begin{document}/\\lstdefinelanguage{JavaScript}{keywords={typeof,new,true,false,catch,function,return,null,catch,switch,var,if,in,while,do,else,case,break},ndkeywords={class,export,boolean,throw,implements,import,this},sensitive=false,comment=[l]{\/\/},morecomment=[s]{\/*}{*\/},morestring=[b]'"'"',morestring=[b]"}\n% "define" Scala\n\\lstdefinelanguage{scala}{\nmorekeywords={abstract,case,catch,class,def,%\ndo,else,extends,false,final,finally,%\nfor,if,implicit,import,match,mixin,%\nnew,null,object,override,package,%\nprivate,protected,requires,return,sealed,%\nsuper,this,throw,trait,true,try,%\ntype,val,var,while,with,yield},\notherkeywords={=>,<-,<\\%,<:,>:,\\#,@},\nsensitive=true,\nmorecomment=[l]{\/\/},\nmorecomment=[n]{\/*}{*\/},\nmorestring=[b]",\nmorestring=[b]'"'"',\nmorestring=[b]"""\n}\n\\setcounter{secnumdepth}{-1}\n\\renewcommand\\contentsname{\\'"'"'Indice}\n&/' book.tex >book.tex-tmp && mv book.tex-tmp book.tex
	# Fix dashes, also probably only for Spanish
	sed 's/ -{}-{}\([^ -]\)/ \\textemdash{}\1/g' book.tex | sed 's/\([^ -]\)-{}-{}\([ ,\.:;)(]\)/\1\\textemdash{}\2/' >book.tex-tmp && mv book.tex-tmp book.tex

clean:
	rm -rf tex-tmp epub-tmp
	rm -f book.tex book.xml cover.pdf
	rm -rf camino_*.chunked camino_*.pdf camino_*.html camino_*.epub
	rm -f camino_*.xml
