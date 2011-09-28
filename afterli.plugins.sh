
hmm "Plugins"

if [ $DEBUG -eq 0 ]; then
	for soubor in $TMPDIR/plugins/${DISTRO}/enabled/*; do
		. $soubor
	done
fi

