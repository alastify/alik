#!/bin/bash

WORKDIR=`dirname $BASH_SOURCE`

if [ $# -eq 0 ]; then
	echo "Očekávám název distribuce"
	exit
fi

DISTRO=$1

# pokud adresář existuje, pak půjde o to aktivovat nebo deaktivovat plugin
if [ -d $WORKDIR/$DISTRO ]; then
	if [ $# -eq 1 ]; then
		echo "Očekávám název pluginu který se má aktivovat/deaktivoat"
		exit
	else
		PLUGIN=$2
		# alg je takový, že pokud plugin existuje v enabled, tak se deaktivuje a pokud není v enabled, tak se aktivuje
		if [ -e $WORKDIR/$DISTRO/enabled/$PLUGIN ]; then
			rm $WORKDIR/$DISTRO/enabled/$PLUGIN
			echo "Plugin ${PLUGIN} deaktivován"
		else
			if [ -e $WORKDIR/$DISTRO/available/$PLUGIN ]; then
				cp $WORKDIR/$DISTRO/available/$PLUGIN $WORKDIR/$DISTRO/enabled/$PLUGIN
				chmod 755 $WORKDIR/$DISTRO/enabled/$PLUGIN
				echo "Plugin ${PLUGIN} aktivován"
			else
				echo "Soubor s pluginem nenalezen"
			fi
		fi
	fi
else 
	mkdir $WORKDIR/$DISTRO
	mkdir $WORKDIR/$DISTRO/enabled
	mkdir $WORKDIR/$DISTRO/available
fi



