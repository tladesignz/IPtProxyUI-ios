#!/bin/sh

#  update-bridges.sh
#  IPtProxyUI
#
#  Created by Benjamin Erhart on 04.10.22.
#  Copyright © 2019 - 2026 Guardian Project. All rights reserved.
#

BASE=$(dirname "$0")
SHARED="$BASE/Sources/IPtProxyUI-Shared"

export UPDATE_BRIDGES_BASE=$BASE

cat "$SHARED/MoatApi.swift" \
	"$SHARED/URLSession+IPtProxyUI.swift" \
	"$SHARED/ApiError.swift" \
	"$BASE/Sources/CocoaPods/Bundle+IPtProxyUI.swift" \
	"$BASE/update-bridges.swift" \
	| /usr/bin/env xcrun --sdk macosx swift -
