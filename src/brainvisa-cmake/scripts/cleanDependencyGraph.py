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

from __future__ import absolute_import, print_function

import sys, os, re

reNode = re.compile( r'\s*"(?P<node>[^"]*)"\s*\[\s*label="(?P<label>[^"]*)"\s*shape="(?P<shape>[^"]*)"\];.*' )
reLink = re.compile( r'\s*"(?P<node1>[^"]*)"\s*-\>\s*"(?P<node2>[^"]*)".*' )
reExclude = re.compile( r'(Aims.*)|(Vip.*)|(.*_test)|(comist.*)' )
excludeNodes = set()
excludeLabels = set( ( 'pthread', '-lpthread' ) )
for line in open( 'dependencies.dot' ).readlines():
  match = reNode.match( line )
  if match:
    print(repr( match.group( 'label' ) ), match.group( 'label' ) in excludeLabels, file=sys.stderr)
    if match.group( 'label' ) in excludeLabels or ( match.group( 'shape' ) == 'house' and reExclude.match( match.group( 'label' ) ) ):
      excludeNodes.add( match.group( 'node' ) )
    else:
      sys.stdout.write( line )
  else:
    match = reLink.match( line )
    if match:
      print(match.group( 'node1' ), match.group( 'node2' ), file=sys.stderr)
    if not match or ( match.group( 'node1' ) not in excludeNodes and match.group( 'node2' ) not in excludeNodes ):
      sys.stdout.write( line )

