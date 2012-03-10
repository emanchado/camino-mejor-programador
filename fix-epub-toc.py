#!/usr/bin/python

import sys
from lxml import etree

toc_file = sys.argv[1]
doc = etree.parse(toc_file)

rootNavPoint = doc.getroot()[2][0]
for navpoint in rootNavPoint:
    i = 0
    while i < len(navpoint):
        if navpoint[i].tag.endswith("navPoint"):
            del(navpoint[i])
        else:
            i = i + 1
print etree.tostring(doc)
