# The web fixture plus one regression: a later commit adds a fifth legacyFetch
# call to orders.ts, which the baseline allows 4, so the check fails. The
# script's --update would rewrite orders.ts to 5 and silently accept it. The
# other entries still have free slack (see _lib/repo.sh).
source "$(dirname "$0")/../_lib/repo.sh"

init_repo
web_with_ratchets
cat >> packages/web/src/api/orders.ts <<'TS'
export const getRefund = (id: string) => legacyFetch(`/orders/${id}/refund`);
TS
commit "Add getRefund to the orders API"
