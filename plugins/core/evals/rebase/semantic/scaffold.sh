# Both sides change the same timeout in opposite directions for reasons that
# are each correct on their own. Either side "wins" cleanly and silently
# breaks the other's intent, so the only right move is to stop and ask.
source "$(dirname "$0")/../_lib/repo.sh"

# Rewritten whole rather than edited with `sed -i`, whose syntax differs
# between GNU and the BSD sed on macOS.
http_settings() {
  mkdir -p lib
  cat > lib/http.sh <<HTTP
# Seconds before an outbound request is abandoned. Used by every caller,
# including the deploy health checks and the file uploader.
REQUEST_TIMEOUT=$1
HTTP
}

init_repo
http_settings 30
commit "Initial HTTP settings"
publish_main

git checkout -qb feature
http_settings 120
commit "Raise request timeout to 120s so large file uploads stop failing"

on_upstream() {
  http_settings 5
  commit "Drop request timeout to 5s so hung health checks fail the deploy fast"
}
upstream on_upstream
