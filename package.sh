
hmm "Package installation"

echo -n "" > $PKGLIST
for soubor in $TMPDIR/packages/${DISTRO}.packages*; do
	count=0
	while read radek; do
		let count++
		echo -n "$radek " | sed -nr 's/^([^-])(.*)$/\1\2/p' >> $PKGLIST
		echo -n "$radek " | sed -nr 's/^-(.*)$/\1/p' >> $UNPKGLIST
	done < $soubor
done

BALICKY=`cat $PKGLIST`
UNBALICKY=`cat $UNPKGLIST`

echo "Packages to be installed: $BALICKY"
echo "Packages to be uninstalled: $UNBALICKY"

if [ $DEBUG -eq 0 ]; then
	$PACUPDATE
	$PACMAN $BALICKY
	if [ $? -gt 0 ]; then
		hmm "Package installation error"
		exit 1
	fi
	$UNPACMAN $UNBALICKY
	if [ $? -gt 0 ]; then
		hmm "Package uninstallation error"
		exit 1
	fi
fi

