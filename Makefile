all: funcionales.html consejospruebas.html herramientas.html

%.html: %.asciidoc
	asciidoc $<
