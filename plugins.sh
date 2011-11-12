
hmm "Plugins"

if [ $DEBUG -eq 0 ]; then
	for soubor in $TMPDIR/plugins/${DISTRO}/enabled/*; do
		. $soubor
		if [ $? -gt 0 ]; then
			hmm "Plugin error"
			exit 1
		fi
	done
fi

