# The web fixture with both ratchets enforced in CI and both carrying slack.
# See _lib/repo.sh for the recorded and measured values.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
web_with_ratchets
