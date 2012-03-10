#!/usr/bin/python

import sys
import re
from subprocess import Popen, PIPE
import HTMLParser

file = sys.argv[1]
lang_sig_re = re.compile(r'\s*<pre class="programlisting">LANGUAGE=(\S+) ')
end_lang_sig_re = re.compile(r'</pre>$')

f = open(file)
state = 'init'
code_html = ""
lang = ""
for line in f:
    m = lang_sig_re.search(line)
    if m:
        state = 'programlisting'
        lang = m.group(1)
        code_html = re.sub(lang_sig_re, '', line)
    elif state == 'programlisting':
        code_html = code_html + line

    if state == 'programlisting' and end_lang_sig_re.search(line):
        code_html = re.sub(end_lang_sig_re, '', code_html)
        line = ""
        state = 'init'
        p = Popen(["source-highlight", "-s", lang], stdin=PIPE, stdout=PIPE)
        code = HTMLParser.HTMLParser().unescape(unicode(code_html, "utf-8"))
        p.stdin.write(code.encode("utf-8"))
        p.stdin.close()
        print p.stdout.read().replace('<pre', '<pre class="programlisting"')

    if state == 'init':
        print line,

f.close()
