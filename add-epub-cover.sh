#!/bin/bash

CONTENT_OPF_PATH=$1
if [ ! -r $CONTENT_OPF_PATH ]; then
    echo "ERROR: Couldn't read $CONTENT_OPF_PATH" 1>&2
    exit 1
fi
xmllint -format $CONTENT_OPF_PATH | sed -e 's/<manifest>/&\n    <item id="cover" media-type="application\/xhtml+xml" href="cover.html"\/>\n    <item id="cover-image" media-type="image\/jpeg" href="cover.jpg"\/>/' -e 's/<spine.*/&\n    <itemref idref="cover" linear="no"\/>/' -e 's/<\/spine>/&\n  <guide>\n    <reference type="cover" title="Book cover" href="cover.html"\/>\n  <\/guide>/'
