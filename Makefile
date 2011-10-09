all: funcionales.html \
    consejospruebas.html \
    herramientas.html \
    documentacion-activa.html

%.html: %.asciidoc
	asciidoc $<

clean:
	rm *.html
