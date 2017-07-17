#!/bin/sh

dir="$(dirname $(readlink -f $0))"
config_dir="$dir/configs"
config="$dir/config"
i3_regen_config="$(readlink -f $0) $@"

if [ "$(echo -e)" = "-e" ]; then
	ECHO=echo
else
	ECHO="echo -e"
fi

gen_config() {
	cat << EOF > "$config"
# THIS FILE WAS GENERATED AUTOMATICALLY WITH THIS COMMAND:
# $i3_regen_config

# DO NOT EDIT THIS FILE DIRECTLY, AS IT IS OVERWRITTEN BY ~/.xsession, AS WELL
# AS ANY TIME THE RELOAD OR RESTART KEYBINDINGS ARE PRESSED!

# YOU SHOULD EDIT THE CONFIG FRAGMENTS UNDER $config_dir INSTEAD.

set \$i3_regen_config $i3_regen_config
EOF

	for fragment in "$@"; do
		if [ -e "$config_dir/$fragment" ]; then
			$ECHO "\n# ===== i3 CONFIG FRAGMENT -- $config_dir/$fragment =====\n" >> "$config"
			cat "$config_dir/$fragment" >> "$config"
		else
			found=0
			for extension in sh py; do
				if [ -x "$config_dir/${fragment}.${extension}" ]; then
					$ECHO "\n# ===== i3 CONFIG FRAGMENT GENERATED BY $config_dir/${fragment}.${extension} =====\n" >> "$config"
					"$config_dir/${fragment}.${extension}" >> "$config"
					found=1
				fi
			done
			if [ "$found" = 0 ]; then
				$ECHO "\n# ===== i3 CONFIG FRAGMENT $fragment NOT FOUND =====\n" >> "$config"
			fi
		fi
	done
}

if [ $# -eq 0 ]; then
	gen_config base generic
else
	gen_config base "$@"
fi

exit 0
