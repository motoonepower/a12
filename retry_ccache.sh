#!/bin/bash

#
# Copyright (C) 2022 GeoPD <geoemmanuelpd2001@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Sorting final zip
compiled_zip() {
	ZIP=$(find $(pwd)/out/target/product/${T_DEVICE}/ -maxdepth 1 -name "*${T_DEVICE}*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
	ZIPNAME=$(basename ${ZIP})
}

# Retry the ccache fill for 99-100% hit rate
retry_ccache () {
	export CCACHE_DIR=/tmp/ccache
	export CCACHE_EXEC=$(which ccache)
	ccache -s
	hit_rate=$(ccache -s | awk 'NR==2 { print $5 }' | tr -d '(' | cut -d'.' -f1)
	if [[ $hit_rate -lt 100 && ! -f out/build_error ]]; then
		echo "Ccache is not fully configured"
		git clone https://${TOKEN}@github.com/motoonepower/a12 cirrus && cd $_
		git commit --allow-empty -m "Retry: Ccache loop $(date -u +"%D %T%p %Z")"
		git push -q
	elif [[  -f out/build_error ]]; then
		echo "Build error occured; Ccache refill is halted"
	else
		echo "Ccache is fully configured"
	fi
}

# Trigger retry only if compilation is not finished
retry_event() {
	if [ -f $(pwd)/out/target/product/${T_DEVICE}/${ZIPNAME} ]; then
		echo "Successful Build"
	else
		retry_ccache
	fi
}

cd /tmp/rom && sleep 115m
compiled_zip
retry_event
