all: funcionales.html \
    consejospruebas.html \
    herramientas.html \
    malos_olores.html \
    documentacion-activa.html \
    calidad.html

%.html: %.asciidoc
	asciidoc $<

clean:
	rm *.html
