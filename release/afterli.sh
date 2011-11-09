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
	OUTPUT="./release/afterli.sh"
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
TMPDIR=/tmp/$$workstation
# generated file with package list for installation
PKGLIST=$TMPDIR/packages/list
## will be overwritten # command for updating repository, see bellow
PACUPDATE=0
## will be overwritten # command for installing packages, see bellow
PACMAN=0
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
			REPODIR="${REPOPREF}/etc/yum.repos.d"
			REPOEXT="repo"
		;;
		debian )
			hmm "Linux distribution: Debian"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		ubuntu )
			hmm "Linux distribution: Ubuntu"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		kubuntu )
			hmm "Linux distribution: Kubuntu"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
			REPODIR="${REPOPREF}/etc/apt/sources.list.d"
			REPOEXT="list"
		;;
		mint )
			hmm "Linux distribution: Mint"
			PACUPDATE="apt-get update"
			PACMAN="apt-get install"
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

#outputs: PACUPDATE, PACMAN, DISTRO, REPODIR, REPOEXT




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
