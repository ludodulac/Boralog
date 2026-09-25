#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD=postgres
P="psql -h 127.0.0.1 -U postgres -d postgres -v ON_ERROR_STOP=1 -X"
$P <<'SQL'
INSERT INTO auth.users(id) VALUES ('00000000-0000-4000-8000-000000000091'),('00000000-0000-4000-8000-000000000092');
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000091',false);
SET ROLE authenticated;
INSERT INTO public.organizations(id,name,slug,created_by) VALUES ('10000000-0000-4000-8000-000000000091','Concurrency Org','concurrency-org','00000000-0000-4000-8000-000000000091');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000091',false);
SET ROLE authenticated;
INSERT INTO public.organization_memberships(organization_id,user_id,status,access_level) VALUES ('10000000-0000-4000-8000-000000000091','00000000-0000-4000-8000-000000000092','active','owner');
RESET ROLE;
SQL
cat >/tmp/a.sql <<'SQL'
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000091',true);
SET LOCAL ROLE authenticated;
UPDATE public.organization_memberships SET access_level='full'
WHERE organization_id='10000000-0000-4000-8000-000000000091' AND user_id='00000000-0000-4000-8000-000000000091';
SELECT 'SESSION_A_OWNER_REMOVED_TX_OPEN';
SELECT pg_sleep(8);
COMMIT;
SELECT 'SESSION_A_COMMITTED';
SQL
cat >/tmp/b.sql <<'SQL'
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000092',true);
SET LOCAL ROLE authenticated;
UPDATE public.organization_memberships SET access_level='full'
WHERE organization_id='10000000-0000-4000-8000-000000000091' AND user_id='00000000-0000-4000-8000-000000000092';
COMMIT;
SQL
$P -f /tmp/a.sql >/tmp/a.log 2>&1 & A=$!
for i in {1..50}; do grep -q SESSION_A_OWNER_REMOVED_TX_OPEN /tmp/a.log 2>/dev/null && break; sleep .1; done
grep -q SESSION_A_OWNER_REMOVED_TX_OPEN /tmp/a.log || { cat /tmp/a.log; exit 1; }
set +e
$P -f /tmp/b.sql >/tmp/b.log 2>&1 & B=$!
sleep 2
if ! kill -0 "$B" 2>/dev/null; then
 wait "$B"; rc=$?; echo "SESSION_B_FINISHED_EARLY=$rc"; cat /tmp/b.log; kill "$A" 2>/dev/null; wait "$A" 2>/dev/null; exit 1
fi
echo SESSION_B_CONFIRMED_WAITING_AFTER_2_SECONDS
wait "$A"; ARC=$?
wait "$B"; BRC=$?
set -e
cat /tmp/a.log; cat /tmp/b.log
echo "SESSION_A_RC=$ARC SESSION_B_RC=$BRC"
test "$ARC" -eq 0
test "$BRC" -ne 0
grep -q "cannot remove the last active owner" /tmp/b.log
COUNT=$($P -Atc "SELECT count(*) FROM public.organization_memberships WHERE organization_id='10000000-0000-4000-8000-000000000091' AND status='active' AND access_level='owner';")
echo "ACTIVE_OWNER_FINAL_COUNT=$COUNT"
test "$COUNT" -ge 1
