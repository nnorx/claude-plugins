# Both sides append a different entry to the end of the same list. The hunks
# are adjacent, so git conflicts, but the resolution is plainly "keep both":
# neither side changed anything the other wrote.
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
cat > services.yaml <<'EOF'
services:
  - api
  - web
EOF
commit "Initial service list"
publish_main

git checkout -qb feature
echo "  - search" >> services.yaml
commit "Add search service"

on_upstream() {
  echo "  - worker" >> services.yaml
  commit "Add worker service"
}
upstream on_upstream
