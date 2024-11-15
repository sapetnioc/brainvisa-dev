# -*- coding: utf-8 -*-
#  This software and supporting documentation are distributed by
#      Institut Federatif de Recherche 49
#      CEA/NeuroSpin, Batiment 145,
#      91191 Gif-sur-Yvette cedex
#      France
#
# This software is governed by the CeCILL-B license under
# French law and abiding by the rules of distribution of free software.
# You can  use, modify and/or redistribute the software under the
# terms of the CeCILL-B license as circulated by CEA, CNRS
# and INRIA at the following URL "http://www.cecill.info".
#
# As a counterpart to the access to the source code and  rights to copy,
# modify and redistribute granted by the license, users are provided only
# with a limited warranty  and the software's author,  the holder of the
# economic rights,  and the successive licensors  have only  limited
# liability.
#
# In this respect, the user's attention is drawn to the risks associated
# with loading,  using,  modifying and/or developing or reproducing the
# software by the user in light of its specific status of free software,
# that may mean  that it is complicated to manipulate,  and  that  also
# therefore means  that it is reserved for developers  and  experienced
# professionals having in-depth computer knowledge. Users are therefore
# encouraged to load and test the software's suitability as regards their
# requirements in conditions enabling the security of their systems and/or
# data to be ensured and,  more generally, to use and operate it in the
# same conditions as regards security.
#
# The fact that you are presently reading this means that you have had
# knowledge of the CeCILL-B license and that you accept its terms.

import sys
import importlib
import re
import os


# found in https://github.com/kovidgoyal/calibre/commit/73a312dd648143006184ed71a0aab7336dc03cc1#diff-74e67b94edb27c8f348abd003df82f462d963c11c9ba0a786d7e73f1f7f9ae24
def pyqt_sip_abi_version(pyqt_mod):
    pyqt = importlib.import_module(pyqt_mod)
    if getattr(pyqt, '__file__', None):
        bindings_path = os.path.join(os.path.dirname(pyqt.__file__),
                                     'bindings', 'QtCore', 'QtCore.toml')
        if os.path.exists(bindings_path):
            with open(bindings_path) as f:
                raw = f.read()
                m = re.search(r'^sip-abi-version\s*=\s*"(.+?)"', raw,
                              flags=re.MULTILINE)
                if m is not None:
                    return m.group(1)


sip_mod = sys.argv[1]
#sip = importlib.import_module(sip_mod)
pyqt_mod = sip_mod.rsplit('.', 1)[0]

print(pyqt_sip_abi_version(pyqt_mod), end='')
