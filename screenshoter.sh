ну#!/usr/bin/env sh
set -euo pipefail

cleanup() {
	[ -z "${swayimg_pid}" ] || kill -TERM "${swayimg_pid}" 2>/dev/null || :
	[ -z "${img}" ] || rm "${img}" 2>/dev/null || :
}

trap cleanup EXIT

img=$(mktemp)
hyprshot -m output -r -s -c > "${img}"

swayimg -f -c "__screenshoter" "${img}" &
swayimg_pid=$!

geometry=$(slurp -f "%o:%wx%h+%x+%y" 2>/dev/null)
[[ "${geometry}" =~ ^(.*?):(.*)$ ]]
output="${BASH_REMATCH[1]}"
scale=1

scale_script='
function do_scale(idx) {
	return int(geometry[idx] * scale);
}

match($0, /^(.*?)x(.*?)\+(.*?)\+(.*?)$/, geometry) {
	printf "%dx%d+%d+%d", do_scale(1), do_scale(2), do_scale(3), do_scale(4);
}
'

geometry=$(awk -v scale="${scale}" "${scale_script}" <<< "${BASH_REMATCH[2]}")
convert "ppm:${img}" -crop "${geometry}" png:- | wl-copy -t image/png
