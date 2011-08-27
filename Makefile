all: funcionales.html consejospruebas.html

%.html: %.asciidoc
	asciidoc $<
