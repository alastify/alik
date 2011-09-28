
hmm "Setting up repositories"

for soubor in $TMPDIR/repos/${DISTRO}*; do
	regex="/${DISTRO}\.([a-zA-Z0-9-]+)\.repo"
	if [[ "$soubor" =~ $regex ]]; then
		novy_soubor=${REPODIR}/${BASH_REMATCH[1]}.${REPOEXT}
		cp $soubor $novy_soubor
	fi
done

hmm "Import of gpgs"
gpgfile="$TMPDIR/repos/${DISTRO}.gpg"
if [ -e $gpgfile ]; then
	count=0
	while read gurl; do
		let count++
		if [ "$gurl" ]; then
			if [ $DEBUG -eq 0 ]; then
				wget -q $gurl -O- | apt-key add -
			fi
		fi
	done < $gpgfile
fi

