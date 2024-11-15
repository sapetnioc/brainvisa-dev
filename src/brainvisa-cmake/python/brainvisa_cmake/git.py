# -*- coding: utf-8 -*-
"""Management of Git repositories in bv_maker."""

import shutil
import os
import subprocess

import six
from six.moves import shlex_quote

from brainvisa_cmake.subprocess import decode_output
from brainvisa_cmake.subprocess import DEVNULL
from brainvisa_cmake.subprocess import system


# FIXME(ylep): move to a utils module
def cached_property(fget):
    """Create a read-only attribute that caches its value."""
    def cached_getter(self):
        try:
            return self._cache[fget.__name__]
        except KeyError:
            pass
        value = fget(self)
        self._cache[fget.__name__] = value
        return value
    return property(cached_getter, doc=fget.__doc__)


class GitUpdateError(Exception):
    """Exception for a non-fatal error updating a Git repository."""
    pass


class GitRepository(object):
    """Class for querying and interacting with a Git repository."""
    def __init__(self, source_directory, dest_directory,
                 remote_url=None, remote_ref=None):
        self.source_directory = source_directory
        self.dest_directory = dest_directory
        self.path = os.path.join(source_directory, dest_directory)
        self.remote_url = remote_url
        self.remote_ref = remote_ref
        self._cache = {}

    def invalidate_cache(self, key=None):
        """Invalidate a cached property (all properties if key=None)."""
        if key is None:
            self._cache.clear()
        else:
            try:
                del self._cache[key]
            except KeyError:
                pass

    def call_command(self, args, echo=False, **kwargs):
        """Call a command in the repository, returning its exit code."""
        if echo:
            if isinstance(args, six.string_types):
                print('$ ' + shlex_quote(args))
            else:
                print('$ ' + ' '.join(shlex_quote(arg) for arg in args))
        return subprocess.call(args, cwd=self.path, **kwargs)

    def call_nonessential_command(self, args, echo=True, **kwargs):
        """Call a command in the repository, ignoring failure."""
        try:
            retcode = self.call_command(args, echo=echo, **kwargs)
        except OSError:
            # "Command not found" scenario
            return
        if echo and retcode != 0:
            print('You can safely ignore errors of the above command')

    @cached_property
    def local_branch(self):
        """Name of the current branch, or None if detached."""
        try:
            head_ref = decode_output(subprocess.check_output(
                ['git', 'symbolic-ref', '--quiet', 'HEAD'],
                cwd=self.path).rstrip())
        except subprocess.CalledProcessError:
            return None
        if head_ref.startswith('refs/heads/'):
            return head_ref[len('refs/heads/'):]

    def sha1_of_rev(self, rev):
        """Obtain the full SHA-1 of the commit identified by rev."""
        try:
            return decode_output(subprocess.check_output(
                ['git', 'rev-parse', '--quiet', '--verify', rev + '^{commit}'],
                cwd=self.path).rstrip())
        except subprocess.CalledProcessError:
            return None

    @cached_property
    def head_short_sha1(self):
        """Shortened SHA-1 identifier of the current HEAD commit."""
        try:
            return decode_output(subprocess.check_output(
                ['git', 'rev-parse', '--quiet', '--verify',
                 '--short', 'HEAD^{commit}'],
                cwd=self.path).rstrip())
        except subprocess.CalledProcessError:
            return None

    @cached_property
    def head_sha1(self):
        """SHA-1 identifier of the current HEAD commit."""
        return self.sha1_of_rev('HEAD')

    @cached_property
    def bv_head_sha1(self):
        """SHA-1 identifier of the commit referenced by refs/bv_head."""
        return self.sha1_of_rev('refs/bv_head')

    @cached_property
    def git_upstream_full_ref(self):
        """Full ref of the current branch's @{upstream}.

        None is returned if there is no @{upstream}.
        """
        try:
            return decode_output(subprocess.check_output(
                ['git', 'rev-parse', '--symbolic-full-name', '@{upstream}'],
                stderr=DEVNULL, cwd=self.path).rstrip())
        except subprocess.CalledProcessError:
            return None

    @cached_property
    def git_upstream_abbrev_ref(self):
        """Abbreviated ref of the current branch's @{upstream}.

        None is returned if there is no @{upstream}.
        """
        try:
            return decode_output(subprocess.check_output(
                ['git', 'rev-parse', '--abbrev-ref', '@{upstream}'],
                stderr=DEVNULL, cwd=self.path).rstrip())
        except subprocess.CalledProcessError:
            return None

    @cached_property
    def full_remote_ref(self):
        """Full ref of the remote-tracking branch representing remote_ref."""
        if self.remote_ref is None:
            return None
        try:
            return decode_output(subprocess.check_output(
                ['git', 'rev-parse', '--symbolic-full-name',
                 'refs/remotes/origin/' + self.remote_ref],
                stderr=DEVNULL, cwd=self.path).rstrip())
        except subprocess.CalledProcessError:
            return None

    @cached_property
    def tree_dirty(self):
        """Test if the repository has uncommitted changes in the worktree."""
        retcode = self.call_command(['git', 'diff', '--no-ext-diff',
                                     '--quiet'])
        return (retcode != 0)

    @cached_property
    def index_dirty(self):
        """Test if the repository has uncommitted changes in the index."""
        retcode = self.call_command(['git', 'diff', '--no-ext-diff',
                                     '--cached', '--quiet'])
        return (retcode != 0)

    @property
    def dirty(self):
        """Test if the repository has uncommitted changes."""
        return self.tree_dirty or self.index_dirty

    def update_origin_and_bv_head(self):
        """Fetch all branches and tags from the 'origin' remote."""
        # Redirect stderr to stdout since git fetch prints progress on stderr,
        # but other BrainVISA tools (e.g. bv_build_nightly) consider every
        # print to stderr to be an error.
        retcode = self.call_command([
            'git', 'fetch', '--tags', '--prune', 'origin',
            '+refs/heads/*:refs/remotes/origin/*',
            # Unfortunately we cannot combine this fetch with fetching
            # remote_ref into refs/bv_head, because this conflicts with --prune
            # (refs/bv_head gets pruned). Confirmed with git version 2.7.4.
            #
            # '+' + self.remote_ref + ':refs/bv_head',
        ], echo=True, stderr=subprocess.STDOUT)
        self.invalidate_cache('full_remote_ref')
        if retcode != 0:
            self.print_command_failure_message('''\
Fetching failed. Please check your Internet connection and access rights
to the origin repository.''')
            raise GitUpdateError('fetch failed')
        self.update_bv_head()

    def update_other_remotes(self):
        """Fetch all remotes except 'origin' (errors are non-fatal)."""
        self.call_nonessential_command(
            ['git', '-c', 'remote.origin.skipDefaultUpdate',
             'remote', 'update'], echo=True)

    @property
    def remote_ref_is_a_branch(self):
        """Test if remote_ref names a branch on the given remote."""
        return self.full_remote_ref is not None

    @staticmethod
    def print_command_failure_message(message):
        """Print a prominent error message referring to the command above."""
        print('^' * 72)
        print(message)
        print('=' * 72)

    @classmethod
    def _setup_git_lfs_global_config(cls):
        """Install git-lfs so that 'git clone' will check out lfs files.

        Errors of 'git lfs install' are ignored, including git lfs not being
        installed.
        """
        if not hasattr(cls, '_git_lfs_is_configured'):
            args = ['git', 'lfs', 'install', '--skip-repo']
            print('$ ' + ' '.join(shlex_quote(arg) for arg in args))
            try:
                subprocess.check_call(args)
            except OSError:
                # "Command not found" scenario
                cls._git_lfs_is_configured = False
            except subprocess.CalledProcessError:
                print('You can safely ignore errors of the above command')
                cls._git_lfs_is_configured = False
            else:
                cls._git_lfs_is_configured = True

    def update_bv_head(self):
        """Change refs/bv_head to point to the given remote ref."""

        if self.remote_ref_is_a_branch:
            # Case 1: if remote_ref points to a branch, use the corresponding
            # remote-tracking branch.
            ref = 'refs/remotes/origin/' + self.remote_ref
        elif self.sha1_of_rev('refs/tags/' + self.remote_ref) is not None:
            # Case 2: if remote_ref points to a tag, use it
            ref = 'refs/tags/' + self.remote_ref
        else:
            # Case 3: neither of the above is true, fall back to using 'git
            # fetch' to fetch the remote ref.
            ref = None

        if ref is not None:
            retcode = self.call_command(['git', 'update-ref', '--no-deref',
                                         'refs/bv_head', ref], echo=True)
            if retcode != 0:
                self.print_command_failure_message(
                    'Failed to update refs/bv_head.')
                raise GitUpdateError('bv_head update failed')
        else:
            # Redirect stderr to stdout since git fetch prints progress on stderr,
            # but other BrainVISA tools (e.g. bv_build_nightly) consider every
            # print to stderr to be an error.
            retcode = self.call_command([
                'git', 'fetch', 'origin',
                "+" + self.remote_ref + ":refs/bv_head"
            ], echo=True, stderr=subprocess.STDOUT)
            self.invalidate_cache('bv_head_sha1')
            if retcode != 0:
                self.print_command_failure_message('''\
Fetching failed. Please check your Internet connection and access rights
to the remote repository.''')
                raise GitUpdateError('fetch failed')

    def checkout_or_create_branch(self, branch, remote='origin'):
        """Check out a branch, or create it from the remote branch."""
        retcode = self.call_command(['git', 'checkout', branch, '--'],
                                    echo=True)
        self.invalidate_cache()
        if retcode != 0:
            retcode = self.call_command(
                ['git', 'checkout', '-b', branch, '--track',
                 'refs/remotes/origin/' + branch])
            if retcode != 0:
                self.print_command_failure_message("""\
The git repository could not be updated, probably because you have
uncommitted local changes (see above).""")
                raise GitUpdateError('checkout failed')

    def try_ff_pull_from_upstream(self):
        """Try to fast-forward from the git-configured @{upstream}.

        This fast-forward is attempted only if @{upstream} is set and is
        different from the remote_ref that bv_maker uses to update the
        repository.

        This is useful e.g. if you are working on a feature branch: it will try
        to pull from the corresponding remote branch if there is one, before
        trying to incorporate changes from the master branch. Failure is
        ignored because this is provided for convenience only.
        """
        # NOTE: if this fails (e.g. because of uncommitted changes or
        # network error), but the remote branch has advanced, the merge
        # from origin (below) may make the local branch diverge from the
        # remote feature branch, which effectively forces the user to merge the
        # commits from master into their branch.
        if (self.git_upstream_full_ref is not None
                and self.git_upstream_full_ref != self.full_remote_ref):
            # Redirect stderr to stdout since git fetch prints progress on
            # stderr, but other BrainVISA tools (e.g. bv_build_nightly)
            # consider every print to stderr to be an error.
            self.call_nonessential_command(['git', 'pull', '--ff-only'],
                                           stderr=subprocess.STDOUT)
            self.invalidate_cache('head_sha1')

    def ff_merge_bv_head(self):
        """Fast-forward merge refs/bv_head into the current branch."""
        retcode = self.call_command(
            ['git', 'merge', '--ff-only', 'refs/bv_head'], echo=True)
        self.invalidate_cache('head_sha1')
        if retcode != 0:
            # TODO(ylep): fall back to resetting the current branch if
            # this is sufficiently safe (useful if a branch is
            # rewritten or rebased).
            self.print_command_failure_message("""\
The upstream branch could not be merged, please refer to the error message
above.""")
            raise GitUpdateError('merge failed')

    def detach_at_bv_head(self):
        """Put the repository in detached state, pointing at refs/bv_head."""
        retcode = self.call_command(
            ['git', 'checkout', '--detach', 'refs/bv_head', '--'], echo=True)
        self.invalidate_cache()
        if retcode != 0:
            self.print_command_failure_message("""\
The Git repository could not be updated, probably because you have
uncommitted local changes (see above).""")
            raise GitUpdateError('checkout failed')

    def print_short_status(self, extra_git_commands=[]):
        print("\nStatus of {0}:".format(self.path))
        if not os.path.exists(os.path.join(self.path, '.git')):
            print('not a Git repository.')
            return
        self.call_command(['git', 'describe'])
        self.call_command(['git', 'status', '--short', '--branch'])
        for command in extra_git_commands:
            self.call_command(command, shell=True, echo=True)

    def get_status_dict(self):
        if not os.path.exists(os.path.join(self.path, '.git')):
            return {
                'source_directory': self.source_directory,
                'dest_directory': self.dest_directory,
                'describe_head': 'ERROR: not a Git repository',
            }
        # Collect information that can be used to build a short status string.
        # This is inspired by git/contrib/completion/git-prompt.sh from the Git
        # official source repository.
        #
        # Get the name of the current branch or description of commit
        describe_head = None
        if self.local_branch is None:
            try:
                describe_head = decode_output(subprocess.check_output(
                    ['git', 'describe', '--always'], cwd=self.path).rstrip())
            except subprocess.CalledProcessError:
                pass

        # Show the stash state of the repository
        retcode = self.call_command(['git', 'rev-parse', '--verify', '--quiet',
                                     'refs/stash'],
                                    stdout=DEVNULL)

        stash = (retcode == 0)

        # Show a marker if there are untracked files
        retcode = self.call_command(['git', 'ls-files', '--others',
                                     '--exclude-standard', '--directory',
                                     '--no-empty-directory', '--error-unmatch',
                                     '--', ':/*'],
                                    stdout=DEVNULL,
                                    stderr=DEVNULL)
        untracked = (retcode == 0)

        # Show upstream info for bv_maker-configured and git-configured
        # upstream
        bv_maker_upstream_ref = self.full_remote_ref
        git_upstream_ref = self.git_upstream_full_ref
        if bv_maker_upstream_ref:
            bv_upstream_info = 'U' + self.behind_ahead_upstream_suffix(
                bv_maker_upstream_ref)
        else:
            bv_upstream_info = ''

        if git_upstream_ref and git_upstream_ref != bv_maker_upstream_ref:
            git_upstream_info = 'u' + self.behind_ahead_upstream_suffix(
                '@{upstream}')
            git_upstream_name = self.git_upstream_abbrev_ref
        else:
            git_upstream_info = ''
            git_upstream_name = ''

        return {
            'source_directory': self.source_directory,
            'dest_directory': self.dest_directory,
            'describe_head': describe_head,
            'current_branch': self.local_branch,
            'head_short_sha1': self.head_short_sha1,
            'tree_dirty': self.tree_dirty,
            'index_dirty': self.index_dirty,
            'stash': stash,
            'untracked': untracked,
            'bv_upstream_info': bv_upstream_info,
            'git_upstream_info': git_upstream_info,
            'git_upstream_name': git_upstream_name,
        }

    def behind_ahead_upstream(self, upstream='@{upstream}'):
        """Get the number of local commits behind and ahead of the upstream.

        (None, None) is returned if the information is unavailable (e.g. the
        specified upstream does not exist).
        """
        try:
            output = subprocess.check_output(
                ['git', 'rev-list', '--count', '--left-right',
                 upstream + '...HEAD'],
                stderr=DEVNULL, cwd=self.path)
            behind, ahead = (int(n) for n in output.split())
        except subprocess.CalledProcessError:
            return None, None
        return behind, ahead

    def behind_ahead_upstream_suffix(self, upstream='@{upstream}'):
        """Get a suffix string representing the number of diverging commits.

        '=' is returned if the current branch is even with upstream. Otherwise,
        '+A-B' is returned, where A and B are the number of commits ahead and
        behind of the branch, respectively. Any '+0' or '-0' part is omitted.

        An empty string is returned if the information is unavailable (e.g. the
        specified upstream does not exist).
        """
        behind, ahead = self.behind_ahead_upstream(upstream)
        if behind is None:
            return ''
        if behind == ahead == 0:
            return '='
        upstream_info = ''
        if ahead != 0:
            upstream_info += '+{0}'.format(ahead)
        if behind != 0:
            upstream_info += '-{0}'.format(behind)
        return upstream_info

    @classmethod
    def have_pre_commit(cls):
        """Test if pre-commit is available."""
        if not hasattr(cls, '_have_pre_commit'):
            cls._have_pre_commit = bool(
                shutil.which('pre-commit')
            )
        return cls._have_pre_commit

    def ensure_origin_remote(self):
        """Ensure the 'origin' remote is configured to the bv_maker URL."""
        retcode = self.call_command(
            ['git', 'remote', 'set-url', 'origin', self.remote_url],
            stderr=DEVNULL,
        )
        if retcode != 0:
            retcode = self.call_command(
                ['git', 'remote', 'add', '--tags',
                 'origin', self.remote_url], echo=True)
            if retcode == 0:
                raise GitUpdateError('remote set-up failed')

    def update_or_clone(self, source_dir):
        """Update or clone the repository."""
        print("\n")
        print("Updating git repository {0}".format(self.path))

        # Clone repository if it does not exist yet locally
        if not os.path.exists(os.path.join(self.path, '.git')):
            if os.path.isdir(self.path) and os.listdir(self.path):
                print('''
ERROR: directory "%s" is not empty, Git will not be able to clone into it.
This error may be due to a repository change for a component (typically
going from Subversion to Git). You must check yourself that you have nothing
to keep in this directory and delete it to make "bv_maker sources" work.'''
                       % self.path)
            self._setup_git_lfs_global_config()
            system('git', 'clone', '--branch', self.remote_ref,
                   self.remote_url, self.path)
        else:
            self.ensure_origin_remote()

        # Fetch the remote ref specified in bv_maker.cfg into refs/bv_head
        #
        # FIXME(ylep): what happens if the update below ends with an error?
        # bv_head is already updated, does that pose a problem?
        # Get the SHA-1 identifiers of HEAD and refs/bv_head commits
        old_bv_head = self.bv_head_sha1
        self.update_origin_and_bv_head()

        # Update other remotes only if the user has explicitly configured
        # update_git_remotes = 'ON'.
        if source_dir.update_git_remotes.upper() == 'ON':
            self.update_other_remotes()

        if self.remote_ref_is_a_branch:
            if ((not self.local_branch and self.head_sha1 == old_bv_head)
                    or self.head_sha1 is None):
                # NOTE: this code path will upgrade repositories that follow a
                # branch in detached mode, which were used until May 2019.
                self.checkout_or_create_branch(self.remote_ref)
                # In case of success, we proceed to do the normal fast-forward
                # update
            elif not self.local_branch:
                print('=' * 72)
                print("""\
The Git repository was not updated, because it is in detached HEAD
state. You can update it manually with:

  git -C '{path}' checkout {remote_ref}
  git pull origin {remote_ref}

If that fails, you can force the re-creation of the local branch (beware
that this could lose local commits on the old '{remote_ref}' branch):

  git -C '{path}' checkout -B {remote_ref} origin/{remote_ref}\
""".format(path=self.path, remote_ref=self.remote_ref))
                print('=' * 72)
                raise GitUpdateError('detached')

            self.try_ff_pull_from_upstream()

            # We are following a branch. Advance the branch if it has not
            # diverged from upstream. If local commits exist, that would
            # require creating a merge commit, and we do not want to do that
            # behind the back of the developer. The merge aborts safely if
            # there are local uncommitted changes, and prints an appropriate
            # message.
            self.ff_merge_bv_head()
        else:  # not self.remote_ref_is_a_branch
            # If self.head_sha1 == old_bv_head, it means that the user has not
            # moved the repository since the last bv_maker run. In this case,
            # we allow ourselves to reconfigure the repository (e.g. check out
            # a different commit).
            if (self.head_sha1 == old_bv_head
                    or not self.head_sha1
                    or not old_bv_head):
                # If remote_ref is not a branch (i.e. it is a tag or a sha-1),
                # we want to detach the repository at this precise commit.
                self.detach_at_bv_head()
            elif self.head_sha1 == self.bv_head_sha1:
                pass  # success (nothing to do!)
            else:
                print('=' * 72)
                print("""\
The Git repository was not updated, because a different commit was
checked out since the last run of bv_maker sources. You can update your
repository manually using the following command:

  git -C '{path}' checkout refs/bv_head\
""".format(path=self.path, remote_ref=self.remote_ref))
                print('=' * 72)
                raise GitUpdateError('detached')

        if (os.path.exists(os.path.join(self.path, '.pre-commit-config.yaml'))
                and self.have_pre_commit()):
            self.call_nonessential_command(['pre-commit', 'install'])


def print_git_status_summary(source_directory, status_list):
    if not status_list:
        return

    header = 'Summary of Git repositories in ' + source_directory
    print('\n' + header)
    print('=' * len(header))

    def format_head(status_dict):
        if status_dict.get('current_branch') is not None:
            return '{current_branch} ({head_short_sha1})'.format(**status_dict)
        else:
            return status_dict['describe_head']

    # Calculate optimal field widths
    head_width = max(max(len(format_head(d)) for d in status_list), 1)
    bv_upstream_width = max(len(d.get('bv_upstream_info', ''))
                            for d in status_list)
    if bv_upstream_width != 0:
        bv_upstream_format = '{{bv_upstream:{0}s}}'.format(bv_upstream_width)
    else:
        bv_upstream_format = ''
    git_upstream_width = max(len(d.get('git_upstream_info', ''))
                             for d in status_list)
    if git_upstream_width != 0:
        git_upstream_format = '{{git_upstream:{0}s}}'.format(
            git_upstream_width)
    else:
        git_upstream_format = ''
    update_message_width = max(len(d.get('update_message', u''))
                               for d in status_list)
    if update_message_width != 0:
        update_message_format = '{{update_message:{0}s}} '.format(
            update_message_width)
        update_message_width += 1
    else:
        update_message_format = ''

    print('┌───── * uncommitted working tree changes')
    print('│┌──── + uncommitted index changes')
    print('││┌─── $ stash present')
    print('│││┌── % untracked files')
    print('││││ ┌ HEAD')
    prefix = '││││ │' + ' ' * head_width
    if update_message_width != 0:
        print(prefix + '┌ update status')
        prefix += '│' + ' ' * (update_message_width - 1)
    print(prefix + '┌ bv_maker upstream state')
    print(prefix + '│' + ' ' * bv_upstream_width + '┌ Git upstream state')
    print(prefix + '│' + ' ' * bv_upstream_width + '│'
          + ' ' * git_upstream_width + '┌ Directory')

    for status_dict in status_list:
        print(u'{{tree_dirty}}{{index_dirty}}{{stash}}{{untracked}} '
              '{{head:{head_width}s}} '
              '{update_message_format}'
              '{bv_upstream_format} {git_upstream_format} '
              '{{dest_directory}}'
              .format(
                  head_width=head_width,
                  bv_upstream_format=bv_upstream_format,
                  git_upstream_format=git_upstream_format,
                  update_message_format=update_message_format,
              )
              .format(
                  dest_directory=status_dict['dest_directory'],
                  head=format_head(status_dict),
                  tree_dirty='*' if status_dict.get('tree_dirty') else ' ',
                  index_dirty='+' if status_dict.get('index_dirty') else ' ',
                  stash='$' if status_dict.get('stash') else ' ',
                  untracked='%' if status_dict.get('untracked') else ' ',
                  bv_upstream=status_dict.get('bv_upstream_info', ''),
                  git_upstream=status_dict.get('git_upstream_info', ''),
                  update_message=status_dict.get('update_message', ''),
              ))
