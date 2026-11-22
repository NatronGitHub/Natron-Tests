# Known failures

Tests that are expected to fail, so that a run of `runTests.sh` can gate a release: it reports them
as `KNOWN FAIL` instead of `FAIL`, and exits with status 1 only if another test fails.

- `common.txt`: known failures on every platform. Known failures should differ very little, or not
  at all, between the platforms, so this is where most of them go.
- `macos.txt`, `linux.txt`, `windows.txt`: the known failures of one platform only. `runTests.sh`
  reads `common.txt` and the list of the platform it runs on (`uname`). `KNOWN_FAILURES`, a
  space-separated list of files, replaces them.

Format: one test name per line, as written in `result.txt` (`TestBlur`, `TestCMD/1`,
`TestWriteFFmpeg/mov_cvid`), optionally followed by a comment: `# reason, issue #N` (the issue is
in NatronGitHub/Natron). Blank lines and lines starting with `#` are ignored. Every entry should
have an issue.

A listed test that passes is reported as `UNEXPECTED PASS`, in `result.txt`, in `summary.txt` and
at the end of the output: remove it from the list (and update its issue). It doesn't fail the run,
because it means that something was fixed, and the run of another platform, or a build of an older
branch, should not fail because the list wasn't updated yet. `KNOWN_FAILURES_STRICT=1` makes
`runTests.sh` exit with status 3 when there is one, e.g. to check that the lists are up to date. A
listed test that didn't run at all (when all the tests run) is reported as `KNOWN FAILURES NOT RUN`.
