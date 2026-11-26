# Known failures

Tests that are expected to fail, so that a run of `runTests.sh` can gate a release: it reports them
as `KNOWN FAIL` instead of `FAIL`, and exits with status 1 only if a test that isn't listed fails, or
if a listed test passes (see below).

- `common.txt`: known failures on every platform. Known failures should differ very little, or not
  at all, between the platforms, so this is where most of them go.
- `macos.txt`, `linux.txt`, `windows.txt`: the known failures of one platform only.
- `arm64.txt`, `x86_64.txt`: the known failures of one CPU architecture only, on every platform.

`runTests.sh` reads `common.txt`, the list of the platform it runs on (`uname -s`) and the list of
its architecture (`uname -m`; on MSYS2, `MSYSTEM_CARCH`), and stops if one of them is missing. Set
`KNOWN_FAILURES_ARCH` (`arm64` or `x86_64`) if the shell's architecture isn't the one of the tested
Natron, for example an x86_64 Natron under Rosetta. A test goes into a platform or architecture list
only when a run shows that it passes elsewhere.

Format: one test name per line, as written in `result.txt` (`TestBlur`, `TestCMD/1`,
`TestWriteFFmpeg/mov_cvid`), optionally followed by a comment: `# reason, issue #N` (the issue is
in NatronGitHub/Natron). Blank lines and lines starting with `#` are ignored.

A listed test that passes is reported as `UNEXPECTED PASS`, in `result.txt`, in `summary.txt` and
at the end of the output, and **fails the run** (exit status 1, `RESULT: FAIL` in `summary.txt`),
like a test that fails and isn't listed: the lists no longer describe the build. Remove the test
from the list, or move it to the lists of the platforms or architectures where it still fails, and
update its issue. A listed test that didn't run at all (when all the tests run) is reported as
`KNOWN FAILURES NOT RUN`; that doesn't fail the run.

Every entry cites an open NatronGitHub/Natron issue: when its issue is closed, either the test
passes again (remove the entry) or the entry needs another open issue.
