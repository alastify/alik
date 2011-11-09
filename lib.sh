
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

