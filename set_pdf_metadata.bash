#!/bin/bash

title=$1
author=$2
url=$3

[[ -z "$3" ]] && echo 'usage <title> <author> <url> <input.pdf >output.pdf' && exit -1

rm -Rf tmp-set_pdf_metadata && mkdir tmp-set_pdf_metadata && cd tmp-set_pdf_metadata 

cat >input.pdf

pdftk input.pdf dump_data output report.txt

echo -e "InfoKey: Title\nInfoValue: ${title}" >>report.txt
echo -e "InfoKey: Author\nInfoValue: ${author}" >>report.txt
echo -e "InfoKey: Url\nInfoValue: ${url}" >>report.txt

pdftk input.pdf update_info report.txt output output.pdf

cat <output.pdf
