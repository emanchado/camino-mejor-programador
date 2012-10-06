#!/bin/bash

RAW_BASE_URL=https://raw.github.com/emanchado/camino-mejor-programador-codigo
PRETTY_BASE_URL=https://github.com/emanchado/camino-mejor-programador-codigo/blob/master

function normalise() {
  snippet=`cat`

  while [[ `echo "$snippet" | wc -l` == `echo "$snippet" | grep '^ ' | wc -l` ]]; do
    snippet=`echo "$snippet" | sed 's/^ //'`
  done

  echo "$snippet"
}

function retrieve_snippet (){
    url="${RAW_BASE_URL}/${1}"
    src="../camino-mejor-programador-codigo/${1}"
    first=$2
    last=$3
    
    sed -n -e "${first},${last} p" "${src}" | normalise
    #curl --fail -s "$url" | sed -n -e "${first},${last} p" | normalise
    #[[ ${PIPESTATUS[0]} != "0" ]] && echo failed to download "$url" && exit -1
}

#matches: '#SNIPPET "a label" some/url.scala 7 27#'
pattern='^#SNIPPET  *"([^"]*)"  *([^ ][^ ]*\.([^ .][^ .]*))  *([0-9][0-9]*)  *([0-9][0-9]*)#$'
while IFS='' read -r LINE; do
  if [[ "$LINE" =~ $pattern ]]; then
    label=${BASH_REMATCH[1]}
    url=${BASH_REMATCH[2]}
    extension=${BASH_REMATCH[3]}
    first=${BASH_REMATCH[4]}
    last=${BASH_REMATCH[5]}

    echo ".${PRETTY_BASE_URL}/${url}[${label}]"
    echo "[source,${extension}]"
    echo -----------------------------------------------------------------------------
    retrieve_snippet "${url}" "${first}" "${last}"
    echo -----------------------------------------------------------------------------
  else
    echo "$LINE"
  fi
done

