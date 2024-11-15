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

from __future__ import absolute_import

import os
import shutil
import subprocess
import tempfile
import unittest
import sys


BV_MAKER_SUBCOMMANDS = ['info', 'sources', 'status', 'configure', 'build',
                        'doc', 'testref', 'test', 'pack', 'install_pack',
                        'testref_pack', 'test_pack', 'publish_pack']


# Test the bv_maker executable from the source tree, with the same version of
# Python that is used to run the tests.
BV_MAKER = [
    sys.executable,
    os.path.abspath(os.path.join(os.path.dirname(__file__),
                                 '..', 'bin', 'bv_maker'))
]


# Variables set in setUpModule()
MODULE_TEST_DIR = None
TEST_REPO_PATH = None
BRAINVISA_CMAKE_REPO = None


def setUpModule():
    global MODULE_TEST_DIR
    global TEST_REPO_PATH
    global BRAINVISA_CMAKE_REPO
    try:
        subprocess.check_call(['git', 'diff', '--no-ext-diff', '--quiet'])
        subprocess.check_call(['git', 'diff', '--no-ext-diff', '--cached',
                               '--quiet'])
    except subprocess.CalledProcessError:
        raise RuntimeError('The current brainvisa-cmake repository has, '
                           'uncommitted changes so bv_maker cannot be '
                           'tested accurately. Please commit any pending '
                           'changes and try again to run the tests.')
    try:
        MODULE_TEST_DIR = tempfile.mkdtemp(prefix='test', suffix='.module')
        TEST_REPO_PATH = MODULE_TEST_DIR
        BRAINVISA_CMAKE_REPO = 'file://' + TEST_REPO_PATH
        subprocess.check_call([
            'git', 'clone', '--bare',
            # Both tox and direct call of pytest set the working directory to
            # the root of the Git repository, so we can use '.' to clone the
            # current repository.
            '.',
            TEST_REPO_PATH
        ])
        current_revision = subprocess.check_output(
            ['git', 'rev-parse', '--verify', 'HEAD'],
            universal_newlines=True
        ).rstrip()
        # To make sure that we are testing the exact same version, we use this
        # trick of creating a tag to the current revision in the repository.
        subprocess.check_call(['git', 'tag', '--force', 'current_rev',
                               current_revision], cwd=TEST_REPO_PATH)
    except BaseException:
        if MODULE_TEST_DIR is not None:
            shutil.rmtree(MODULE_TEST_DIR)
        raise


def tearDownModule():
    shutil.rmtree(MODULE_TEST_DIR)


class TestWithoutRepository(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            cls.test_dir = tempfile.mkdtemp(prefix='test', suffix='.run')
            cls.src_dir = os.path.join(cls.test_dir, 'src')
            cls.build_dir = os.path.join(cls.test_dir, 'build')
            cls.bv_maker_cfg = os.path.join(cls.test_dir, '.brainvisa',
                                            'bv_maker.cfg')
            os.makedirs(os.path.join(cls.test_dir, '.brainvisa'))
            with open(cls.bv_maker_cfg, 'w') as f:
                f.write("""\
[ source {src_dir} ]
  git {repo} current_rev development/brainvisa-cmake
""".format(src_dir=cls.src_dir, build_dir=cls.build_dir,
           repo=BRAINVISA_CMAKE_REPO))
            cls.env = os.environ.copy()
            cls.env['HOME'] = cls.test_dir
        except BaseException:
            if hasattr(cls, 'test_dir'):
                shutil.rmtree(cls.test_dir)
            raise

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.test_dir)

    def test_bv_maker_help(self):
        retcode = subprocess.call(BV_MAKER + ['--help'], env=self.env)
        self.assertEqual(retcode, 0)
        for subcommand in BV_MAKER_SUBCOMMANDS:
            retcode = subprocess.call(BV_MAKER + [subcommand, '--help'],
                                      env=self.env)
            self.assertEqual(retcode, 0)

    def test_bv_maker_sources(self):
        retcode = subprocess.call(BV_MAKER + ['-c', self.bv_maker_cfg,
                                   'sources'], env=self.env)
        self.assertEqual(retcode, 0)
        self.assertTrue(os.path.isfile(os.path.join(
            self.src_dir, 'development', 'brainvisa-cmake',
            'project_info.cmake')))


class TestWithRepository(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            cls.test_dir = tempfile.mkdtemp(prefix='test', suffix='.run')
            cls.src_dir = os.path.join(cls.test_dir, 'src')
            cls.build_dir = os.path.join(cls.test_dir, 'build')
            cls.bv_maker_cfg = os.path.join(cls.test_dir, '.brainvisa',
                                            'bv_maker.cfg')
            os.makedirs(os.path.join(cls.test_dir, '.brainvisa'))
            with open(cls.bv_maker_cfg, 'w') as f:
                f.write("""\
[ source {src_dir} ]
  git {repo} current_rev development/brainvisa-cmake

[ build {build_dir} ]
  cmake_options = -DBRAINVISA_IGNORE_BUG_GCC_5:BOOL=YES
  + {src_dir}/development/brainvisa-cmake
""".format(src_dir=cls.src_dir, build_dir=cls.build_dir,
           repo=BRAINVISA_CMAKE_REPO))
            cls.env = os.environ.copy()
            cls.env['HOME'] = cls.test_dir
            subprocess.check_call(BV_MAKER + ['-c', cls.bv_maker_cfg,
                                              'sources'], env=cls.env)
        except BaseException:
            if hasattr(cls, 'test_dir'):
                shutil.rmtree(cls.test_dir)
            raise

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.test_dir)

    def test01_bv_maker_info(self):
        retcode = subprocess.call(BV_MAKER + ['-c', self.bv_maker_cfg,
                                   'info'], env=self.env)
        self.assertEqual(retcode, 0)
        retcode = subprocess.call(BV_MAKER + ['info'], env=self.env)
        self.assertEqual(retcode, 0)

    def test02_bv_maker_status(self):
        retcode = subprocess.call(BV_MAKER + ['status'], env=self.env)
        self.assertEqual(retcode, 0)

    def test02_bv_maker_status_ascii_locale(self):
        c_locale_env = self.env.copy()
        c_locale_env['LC_ALL'] = 'C'
        retcode = subprocess.call(BV_MAKER + ['status'], env=c_locale_env)
        self.assertEqual(retcode, 0)

    def test03_bv_maker_configure(self):
        retcode = subprocess.call(BV_MAKER + ['configure'], env=self.env)
        self.assertEqual(retcode, 0)
        # Verify that bv_maker has bootstrapped itself in the build tree
        self.assertTrue(os.path.isfile(os.path.join(self.build_dir,
                                                    'bin', 'bv_maker')))


if __name__ == '__main__':
    unittest.main()
