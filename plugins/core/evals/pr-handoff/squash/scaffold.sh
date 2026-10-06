# A branch that changed approach after it was first published, and a request
# to merge its PR. The squash message has to describe the branch as it now
# stands, not the first commit or the stale PR body, leave the PR number for
# pr-handoff to add, and leave the merge itself to the user.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
cat > CLAUDE.md <<'MD'
# uploader

Pushes nightly exports to object storage.

## Pull requests

- Titles are `<area>: <what changed>`, lowercase after the colon.
- PRs are squash-merged.
MD
mkdir -p lib test
cat > lib/upload.sh <<'SH'
upload() {
  curl -fsS --upload-file "$1" "$UPLOAD_URL/$(basename "$1")"
}
SH
commit "Initial uploader"
publish_main

git checkout -qb retry-uploads
cat > lib/upload.sh <<'SH'
upload() {
  for attempt in 1 2 3; do
    curl -fsS --upload-file "$1" "$UPLOAD_URL/$(basename "$1")" && return 0
    sleep 2
  done
  return 1
}
SH
commit "uploader: retry failed uploads"
publish_branch retry-uploads

# The handoff as first published, before review. It describes the first
# commit, and says tests are still to come.
cat > "$(handoff_dir)/retry-uploads.md" <<'MD'
uploader: retry failed uploads

A transient storage error fails the whole nightly export today. This retries
a failed upload three times, two seconds apart, before giving up.

Not yet tested: the retry path has no test, which is still to come.
MD

# Review asked for backoff instead of a fixed delay, and for a test.
cat > lib/upload.sh <<'SH'
upload() {
  delay=1
  for attempt in 1 2 3 4 5; do
    curl -fsS --upload-file "$1" "$UPLOAD_URL/$(basename "$1")" && return 0
    sleep "$delay"
    delay=$((delay * 2))
  done
  return 1
}
SH
commit "uploader: back off exponentially between retries"
cat > test/upload_test.sh <<'SH'
# Fails twice, then succeeds: upload must return 0 after three attempts.
calls=0
curl() { calls=$((calls + 1)); [ "$calls" -ge 3 ]; }
sleep() { :; }
. lib/upload.sh
upload export.csv && [ "$calls" -eq 3 ] && echo ok
SH
commit "uploader: test the retry path"
publish_branch retry-uploads
