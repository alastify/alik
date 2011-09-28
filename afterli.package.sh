
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
fi

