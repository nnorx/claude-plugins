# The web fixture, but CI runs the legacy-API check with continue-on-error, so
# it reports and never blocks. Tightening its baseline changes nothing until
# the check can fail the build, which makes that the headline finding.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
web_with_ratchets "        continue-on-error: true"
