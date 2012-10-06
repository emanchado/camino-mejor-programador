#!/bin/bash

RAW_BASE_URL=https://raw.github.com/jcaraballo/neverread
PRETTY_BASE_URL=https://github.com/jcaraballo/neverread/blob

function normalise() {
  snippet=`cat`

  while [[ `echo "$snippet" | wc -l` == `echo "$snippet" | grep '^ ' | wc -l` ]]; do
    snippet=`echo "$snippet" | sed 's/^ //'`
  done

  echo "$snippet"
}

function retrieve_snippet (){
    url=$1
    first=$2
    last=$3
    
    curl --fail -s "$url" | sed -n -e "${first},${last} p" | normalise
    [[ ${PIPESTATUS[0]} != "0" ]] && echo failed to download "$url" && exit -1
}

#matches: '#SNIPPET "a label" some/url.scala 7 27#'
pattern='^#SNIPPET  *"([^"]*)"  *([^ ][^ ]*\.([^ .][^ .]*))  *([0-9][0-9]*)  *([0-9][0-9]*)#$'
while read LINE; do
  if [[ "$LINE" =~ $pattern ]]; then
    label=${BASH_REMATCH[1]}
    url=${BASH_REMATCH[2]}
    extension=${BASH_REMATCH[3]}
    first=${BASH_REMATCH[4]}
    last=${BASH_REMATCH[5]}

    echo ".${PRETTY_BASE_URL}/${url}[${label}]"
    echo "[source,${extension}]"
    echo -----------------------------------------------------------------------------
    retrieve_snippet "${RAW_BASE_URL}/${url}" "${first}" "${last}"
    echo -----------------------------------------------------------------------------
  else
    echo "$LINE"
  fi
done

