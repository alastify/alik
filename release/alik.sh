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
p3A5ALgBAA==
