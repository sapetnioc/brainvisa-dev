# -*- coding: utf-8 -*-

from __future__ import absolute_import, print_function

import os
import sys

dirs = []
exclude = set()
if len(sys.argv) >= 2:
    exclude.update(sys.argv[1].split(';'))
for p in sys.path:
    if os.path.basename(p) == 'site-packages' and p not in dirs and p not in exclude and not any([p.startswith(p2 + os.sep) for p2 in exclude]):
        to_del = []
        for p2 in dirs:
            if p2.startswith(p + os.sep):
                to_del.append(p2)
        for p2 in to_del:
            dirs.remove(p2)
        dirs.append(p)
        exclude.add(p)

sys.stdout.write(';'.join(dirs))
