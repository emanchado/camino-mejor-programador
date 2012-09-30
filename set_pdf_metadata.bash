#!/bin/bash

title=$1
author=$2

[[ -z "$2" ]] && echo 'usage title author <input.pdf >output.pdf' && exit -1

rm -Rf tmp-set_pdf_metadata && mkdir tmp-set_pdf_metadata && cd tmp-set_pdf_metadata 

cat >input.pdf

pdftk input.pdf dump_data output report.txt
echo -e 'InfoKey: Title\nInfoValue: El camino a un mejor programador' >>report.txt
echo -e 'InfoKey: Author\nInfoValue: Varios Autores' >>report.txt
pdftk input.pdf update_info report.txt output output.pdf

cat <output.pdf
