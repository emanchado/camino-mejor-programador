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
