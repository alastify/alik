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
zo5/sMmqgAC4AQA=
