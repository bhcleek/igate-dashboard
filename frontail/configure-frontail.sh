#!/usr/bin/env bash

set -euC -o pipefail

sed -f - -i /usr/local/bin/tail-station-logs <<EOF
	s/__CALL__/${CALL}/g
EOF
