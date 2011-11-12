
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


