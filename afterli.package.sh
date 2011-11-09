
hmm "Package installation"

echo -n "" > $PKGLIST
for soubor in $TMPDIR/packages/${DISTRO}.packages*; do
	count=0
	while read radek; do
		let count++
		echo -n "$radek " >> $PKGLIST
	done < $soubor
done

BALICKY=`cat $PKGLIST`

echo "Packages: $BALICKY"

if [ $DEBUG -eq 0 ]; then
	$PACUPDATE
	$PACMAN $BALICKY
	if [ $? -gt 0 ]; then
		hmm "Package installation error"
		exit 1
	fi
fi

