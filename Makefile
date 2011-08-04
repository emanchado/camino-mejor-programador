all: funcionales.html

funcionales.html: funcionales.asciidoc
	asciidoc $<
