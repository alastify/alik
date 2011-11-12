#!/bin/bash


function err {
	echo $1 1>&2
}

function hmm {
	echo $1
}

function debg {
	if [ ${DEBUG} -eq 1 ]; then
		hmm $1
		echo -n "Pause"
		read
	fi
}

function build_gzip {
	tar -zcf ./cache/resource packages/ repos/ plugins/
}

function untar_archive {
	OUT=1
	CURDIR=`pwd`
	mkdir $TMPDIR
	if [ -d $TMPDIR ]; then
		cd $TMPDIR
		if [ $? -eq 0 ]; then
			najdi_zacatek=$(grep --text --line-number '^MYARCHIVEDATA:$' $CURDIR/$0 | cut -d ':' -f 1)
			if [ $? -eq 0 ]; then
				zacatek=$((najdi_zacatek + 1))
				tail -n +$zacatek $CURDIR/$0 | base64 -d | tar -zxf -
				if [ $? -eq 0 ]; then
					OUT=0
				fi
			fi
			cd $CURDIR
		fi
	fi

	return $OUT
}

function kompilace {
	# destination
	OUTPUT="./release/alik.sh"
	# list of shell scripts to combine together, order is mandatory
	skripty=( \
		"lib.sh" \
		"init.sh" \
		"before.sh" \
		"repo.sh"  \
		"package.sh" \
		"after.sh" \
		"plugins.sh" \
	)

	## heading
	echo "#!/bin/bash" > $OUTPUT

	## combining
	for sk in "${skripty[@]}"; do
		echo ""  >> $OUTPUT
		cat ./$sk >> $OUTPUT
	done

	## terminating
	echo "hmm \"Done\"" >> $OUTPUT
	echo "exit 0" >> $OUTPUT

	## attachment
	build_gzip
	echo "MYARCHIVEDATA:" >> $OUTPUT
	base64 ./cache/resource >> $OUTPUT

	## execution rights
	chmod 744 $OUTPUT

	hmm "Done"
}



# if the debug is on (=1) nothing will actually happen, script will just run through, but withou installing anything
DEBUG=0
# prefix of repo dir (testing purporses only)
REPOPREF=""

#
BASH=/bin/bash
# temp dir for files
TMPDIR=/tmp/alik.$$
# generated file with package list for installation/uninstallation
PKGLIST=$TMPDIR/packages/list
UNPKGLIST=$TMPDIR/packages/unlist
## will be overwritten # command for updating repository, see bellow
PACUPDATE=0
## will be overwritten # command for installing packages, see bellow
PACMAN=0
## will be overwritten # command for uninstalling packages, see bellow
UNPACMAN=0
## will be overwritten # (code) name of a Linux distribution, see bellow
DISTRO=0
## will be overwritten # default dir for storing repo files, see bellow
REPODIR=0
## will be overwritten # extension of repo files, see bellow
REPOEXT=0


if [ "$(id -u)" != "0" ]; then
	err "You may need to be a root"
fi

if [ $# -eq 0 ]; then
	## list need to be updated manualy, according to cases bellow
	err "Missing distribution name [fedora|debian|ubuntu|kubuntu|mint] or [make]"
	exit
else
	case "$1" in
		fedora )
			hmm "Linux distribution: Fedora"
			PACUPDATE="yum update"
			PACMAN="yum install"
			UNPACMAN="yum remove"
			REPODIR="${REPOPREF}/etc/yum.repos.d"
			REPOEXT="repo"
		;;
		debian )
			hmm "Linux distribution: Debian"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			UNPACMAN="apt-get remove"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		ubuntu )
			hmm "Linux distribution: Ubuntu"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			UNPACMAN="apt-get remove"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		kubuntu )
			hmm "Linux distribution: Kubuntu"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			UNPACMAN="apt-get remove"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		mint )
			hmm "Linux distribution: Mint"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			UNPACMAN="apt-get remove"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		make )
			hmm "Compiling"
			kompilace
			exit
		;;
		* )
			err "Unknown distro"
			exit
		;;
	esac
	DISTRO=$1;
fi

# rozbali archiv do docasneho adresare
if [ "$DISTRO" != "0" ]; then
	untar_archive
	if [ $? -eq 1 ]; then
		err "Could not untar archive to temporary location!"
		exit
	fi
fi

#outputs: PACUPDATE, PACMAN, UNPACMAN, DISTRO, REPODIR, REPOEXT




hmm "Before installation commands"

## none here so far




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



hmm "After installation commands"

## none here so far




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

hmm "Done"
exit 0
MYARCHIVEDATA:
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
