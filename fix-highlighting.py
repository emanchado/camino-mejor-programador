#!/usr/bin/python

import sys
import re
from subprocess import Popen, PIPE

file = sys.argv[1]
lang_sig_re = re.compile(r'\s*<pre class="programlisting">LANGUAGE=(\S+) ')
end_lang_sig_re = re.compile(r'</pre>$')

f = open(file)
state = 'init'
code = ""
lang = ""
for line in f:
    m = lang_sig_re.search(line)
    if m:
        state = 'programlisting'
        lang = m.group(1)
        code = re.sub(lang_sig_re, '', line)
    elif state == 'programlisting':
        code = code + line

    if state == 'programlisting' and end_lang_sig_re.search(line):
        code = re.sub(end_lang_sig_re, '', code)
        line = ""
        state = 'init'
        p = Popen(["source-highlight", "-s", lang], stdin=PIPE, stdout=PIPE)
        p.stdin.write(code)
        p.stdin.close()
        print p.stdout.read().replace('<pre', '<pre class="programlisting"')

    if state == 'init':
        print line,

f.close()
