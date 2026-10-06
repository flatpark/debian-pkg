#!/usr/bin/env bash
# Every DT_NEEDED resolves on a stock sid install (catches a missing Depends).
set -euo pipefail
if ldd /usr/bin/strata | grep 'not found'; then exit 1; fi
