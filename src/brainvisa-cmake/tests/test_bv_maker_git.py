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


# Test the bv_maker executable from the source tree, with the same version of
# Python that is used to run the tests.
BV_MAKER = [
    sys.executable,
    os.path.abspath(os.path.join(os.path.dirname(__file__),
                                 '..', 'bin', 'bv_maker'))
]


class GitUpdateTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            # Set up an immutable repository with a few commits, branches, and
            # tags
            cls.cls_dir = tempfile.mkdtemp(prefix='test', suffix='.cls')
            cls.prepared_repo = os.path.join(cls.cls_dir, 'testrepo')
            os.mkdir(cls.prepared_repo)
            subprocess.check_call(['git', 'init'], cwd=cls.prepared_repo)
            with open(os.path.join(cls.prepared_repo, 'test.txt'), 'w') as f:
                f.write('initial contents\n')
            subprocess.check_call(['git', 'update-index', '--add', 'test.txt'],
                                  cwd=cls.prepared_repo)
            subprocess.check_call(['git',
                                   '-c', 'user.name=Dummy',
                                   '-c', 'user.email=dummy@dummy.test',
                                   'commit', '-m', 'Initial commit'],
                                  cwd=cls.prepared_repo)
            subprocess.check_call(['git',
                                   '-c', 'user.name=Dummy',
                                   '-c', 'user.email=dummy@dummy.test',
                                   'tag', '-a', '-m', 'tag message', 'v0.0.0'],
                                  cwd=cls.prepared_repo)
            cls.v000_sha1 = subprocess.check_output(
                ['git', 'rev-parse', '--verify', 'HEAD^{commit}'],
                cwd=cls.prepared_repo).rstrip()
            subprocess.check_call(['git', 'checkout', '-b', 'branchA'],
                                  cwd=cls.prepared_repo)
            with open(os.path.join(cls.prepared_repo, 'test.txt'), 'w') as f:
                f.write('branchA contents\n')
            subprocess.check_call(['git', 'update-index', 'test.txt'],
                                  cwd=cls.prepared_repo)
            subprocess.check_call(['git',
                                   '-c', 'user.name=Dummy',
                                   '-c', 'user.email=dummy@dummy.test',
                                   'commit', '-m', 'Commit on branchA'],
                                  cwd=cls.prepared_repo)
            cls.branchA_sha1 = subprocess.check_output(
                ['git', 'rev-parse', '--verify', 'HEAD^{commit}'],
                cwd=cls.prepared_repo).rstrip()
            subprocess.check_call(['git', 'checkout', 'master'],
                                  cwd=cls.prepared_repo)
            with open(os.path.join(cls.prepared_repo, 'test.txt'), 'w') as f:
                f.write('newer master contents\n')
            subprocess.check_call(['git', 'update-index', 'test.txt'],
                                  cwd=cls.prepared_repo)
            subprocess.check_call(['git',
                                   '-c', 'user.name=Dummy',
                                   '-c', 'user.email=dummy@dummy.test',
                                   'commit', '-m', 'Newer commit on master'],
                                  cwd=cls.prepared_repo)
            cls.master_sha1 = subprocess.check_output(
                ['git', 'rev-parse', '--verify', 'HEAD^{commit}'],
                cwd=cls.prepared_repo).rstrip()
        except BaseException:
            if hasattr(cls, 'cls_dir'):
                shutil.rmtree(cls.cls_dir)
            raise

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.cls_dir)

    def setUp(self):
        try:
            self.test_dir = tempfile.mkdtemp(prefix='test', suffix='.run')
            self.testrepo = os.path.join(self.test_dir, 'testrepo')
            subprocess.check_call(['git', 'clone',
                                   self.prepared_repo, self.testrepo])
            self.src_dir = os.path.join(self.test_dir, 'src')
            self.clone_path = os.path.join(self.src_dir, 'test')
            self.bv_maker_cfg = os.path.join(self.test_dir, '.brainvisa',
                                             'bv_maker.cfg')
            os.makedirs(os.path.join(self.test_dir, '.brainvisa'))
            with open(self.bv_maker_cfg, 'w') as f:
                f.write("""\
[ source {src_dir} ]
  git file://{testrepo} master test
""".format(src_dir=self.src_dir, testrepo=self.testrepo))
            self.tag_bv_maker_cfg = os.path.join(self.test_dir,
                                                 'bv_maker_tag.cfg')
            with open(self.tag_bv_maker_cfg, 'w') as f:
                f.write("""\
[ source {src_dir} ]
  git file://{testrepo} v0.0.0 test
""".format(src_dir=self.src_dir, testrepo=self.testrepo))
            self.env = os.environ.copy()
            self.env['HOME'] = self.test_dir
        except BaseException:
            if hasattr(self, 'test_dir'):
                shutil.rmtree(self.test_dir)
            raise

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def make_commit_in_testrepo(self, qualifier='new'):
        """Make a commit on HEAD and return its SHA-1."""
        with open(os.path.join(self.testrepo, 'test.txt'), 'w') as f:
            f.write('{0} contents\n'.format(qualifier))
        subprocess.check_call(['git', 'update-index', 'test.txt'],
                              cwd=self.testrepo)
        subprocess.check_call(['git',
                               '-c', 'user.name=Dummy',
                               '-c', 'user.email=dummy@dummy.test',
                               'commit', '-m', '{0} commit'.format(qualifier)],
                              cwd=self.testrepo)
        return subprocess.check_output(['git', 'rev-parse', '--verify',
                                        'HEAD^{commit}'],
                                       cwd=self.testrepo).rstrip()

    def test_clone_and_follow_branch(self):
        # Test fresh clone of the master branch
        retcode = subprocess.call(
            BV_MAKER + ['sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1, 'invalid HEAD after clone')
        output = subprocess.check_output(['git', 'symbolic-ref', 'HEAD'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, b'refs/heads/master',
                         'HEAD should point to the master branch after clone')

        # Test fast-forwarding of branch
        new_commit = self.make_commit_in_testrepo()
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to fast-forward branch')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, new_commit, 'fast-forward failed')

        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'status', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker status failed')


    def test_dirty_repository_update(self):
        # Test fresh clone of the master branch
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')

        # Make the repository dirty
        with open(os.path.join(self.clone_path, 'test.txt'), 'w') as f:
            f.write('dirty contents\n')

        # Test fast-forward update of branch
        new_commit = self.make_commit_in_testrepo()
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertNotEqual(retcode, 0, 'bv_maker should fail in dirty repo')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1,
                         'the repository should not have been updated')

        # Test checking out a tag
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.tag_bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertNotEqual(retcode, 0, 'bv_maker should fail in dirty repo')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1,
                         'the repository should not have been updated')

    def test_fetch_failure(self):
        # Test fresh clone of unreachable repository
        os.rename(self.testrepo, self.testrepo + '.bak')
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertNotEqual(retcode, 0, 'bv_maker should fail to clone from an'
                            'unreachable repository')

        # Put the repository back in place to allow a fresh clone
        os.rename(self.testrepo + '.bak', self.testrepo)
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')

        # Test update of unreachable repository
        os.rename(self.testrepo, self.testrepo + '.bak')
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertNotEqual(retcode, 0, 'bv_maker should fail to update from '
                            'an unreachable repository')

    def test_branch_to_tag_to_branch(self):
        # First, clone the repository to follow a branch
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1, 'invalid HEAD after clone')
        output = subprocess.check_output(['git', 'symbolic-ref', 'HEAD'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, b'refs/heads/master',
                         'HEAD should point to the master branch after clone')

        # Then, switch to following a tag
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.tag_bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to update')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.v000_sha1,
                         'HEAD should point at the tag')
        retcode = subprocess.call(['git', 'symbolic-ref', '--quiet', 'HEAD'],
                                  cwd=self.clone_path)
        self.assertNotEqual(retcode, 0,
                            'HEAD should be detached when following a tag')

        # Finally, get back to following a branch
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to update')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1,
                         'HEAD should point at master')
        output = subprocess.check_output(['git', 'symbolic-ref', 'HEAD'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, b'refs/heads/master',
                         'HEAD should point to the master branch after clone')

    def test_upgrade_old_repos(self):
        # Simulate a detached-mode repository as created by bv_maker before May
        # 2019.
        os.makedirs(self.clone_path)
        subprocess.check_call(['git', 'clone', self.testrepo, self.clone_path])
        subprocess.check_call(['git', 'update-ref', 'refs/bv_head', 'HEAD'],
                              cwd=self.clone_path)
        subprocess.check_call(['git', 'checkout', '--detach', 'refs/bv_head'],
                              cwd=self.clone_path)

        # Test the upgrade path for detached-mode repositories, which were put
        # in this state by bv_maker before May 2019.
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1,
                         'invalid HEAD after upgrade from detached mode')
        output = subprocess.check_output(['git', 'symbolic-ref', 'HEAD'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, b'refs/heads/master',
                         'HEAD should point to the master branch after '
                         'upgrade from detached mode')

    def test_manually_detached_repo(self):
        os.makedirs(self.clone_path)
        subprocess.check_call(['git', 'clone', self.testrepo, self.clone_path])
        subprocess.check_call(['git', 'update-ref', 'refs/bv_head', 'HEAD'],
                              cwd=self.clone_path)
        subprocess.check_call(['git', 'checkout', 'v0.0.0'],
                              cwd=self.clone_path)

        # Test that bv_maker does not mess with repositories that were manually
        # put in detached mode.
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertNotEqual(retcode, 0, 'bv_maker should fail upon attempting '
                            'to update a manually detached repository')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.v000_sha1,
                         'HEAD has been changed but should not')
        retcode = subprocess.call(['git', 'symbolic-ref', '--quiet', 'HEAD'],
                                 cwd=self.clone_path)
        self.assertNotEqual(retcode, 0, 'HEAD should still be detached')

    # Unimplemented for now: following an upstream rebase/rewrite when there
    # are no local changes.
    @unittest.expectedFailure
    def test_diverging_upstream_branch(self):
        self.make_commit_in_testrepo()
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')

        # Diverge upstream branch
        subprocess.check_call(['git', 'reset', '--hard', 'branchA'],
                              cwd=self.testrepo)
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0,
                         'bv_maker failed to follow a diverging upstream')

    def test_clone_tag(self):
        retcode = subprocess.call(
            BV_MAKER + ['-c', self.tag_bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.v000_sha1, 'invalid HEAD after clone')
        retcode = subprocess.call(['git', 'symbolic-ref', '--quiet', 'HEAD'],
                                  cwd=self.clone_path)
        self.assertNotEqual(retcode, 0,
                            'HEAD should be detached after cloning a tag')

    # Currently unsupported (git clone does not support passing HEAD to
    # --branch).
    @unittest.expectedFailure
    def test_clone_HEAD(self):
        with tempfile.NamedTemporaryFile(mode='w', delete=False,
                                         prefix='bv_maker', suffix='.cfg',
                                         dir=self.test_dir) as f:
            f.write("""\
[ source {src_dir} ]
  git file://{testrepo} HEAD test
""".format(src_dir=self.src_dir, testrepo=self.testrepo))
        bv_maker_cfg = f.name
        retcode = subprocess.call(
            BV_MAKER + ['-c', bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1, 'invalid HEAD after clone')

    # Currently unsupported (git clone does not support passing a SHA-1 to
    # --branch).
    @unittest.expectedFailure
    def test_clone_sha1(self):
        with tempfile.NamedTemporaryFile(mode='w', delete=False,
                                         prefix='bv_maker', suffix='.cfg',
                                         dir=self.test_dir) as f:
            f.write("""\
[ source {src_dir} ]
  git file://{testrepo} {sha1} test
""".format(src_dir=self.src_dir, testrepo=self.testrepo,
           sha1=self.master_sha1))
        bv_maker_cfg = f.name
        retcode = subprocess.call(
            BV_MAKER + ['-c', bv_maker_cfg, 'sources', '--no-svn'],
            env=self.env)
        self.assertEqual(retcode, 0, 'bv_maker failed to clone')
        output = subprocess.check_output(['git', 'rev-parse', '--verify',
                                          'HEAD^{commit}'],
                                         cwd=self.clone_path).rstrip()
        self.assertEqual(output, self.master_sha1, 'invalid HEAD after clone')
        retcode = subprocess.call(['git', 'symbolic-ref', '--quiet', 'HEAD'],
                                  cwd=self.clone_path)
        self.assertNotEqual(retcode, 0,
                            'HEAD should be detached after cloning a commit')


if __name__ == '__main__':
    unittest.main()
