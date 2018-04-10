#!/bin/bash
ERR_NUM=0
ERR_LIST=""

progressbar () {
	barlength=50
	bar=$(printf "%${barlength}s\n" | tr ' ' '#')
	bar2=$(printf "%${barlength}s\n" | tr ' ' '-')
	n=$(($1*barlength/$2))
	n2=$((barlength-n))
	printf "\r[%-${barlength}s (%d%%)] \n" "${bar:0:n}${bar2:0:n2}" "$(echo $1/$2*100 | bc -l | sed 's/\..*//g')"
}

function update_repo () {
	DIR=$1
	cd $DIR
	set +e
	git fetch --all >/dev/null
#	git reset --hard HEAD >/dev/null
	git branch -r --sort=-committerdate | head -n1 | sed 's/\s*origin\///g' | xargs git checkout >/dev/null
	git pull
	if [ $? = '0' ]; then
          ERR_LIST="${DIR} ${ERR_LIST}"
          (( ERR_NUM++ ))
        fi
	set -e
        cd ..
}

function get_dirs () {
	DIR_REGEX=$1
	LIST=$(find . -maxdepth 1 -type d -printf "%f\n" | egrep "${DIR_REGEX}" | egrep -v '\.')
	ROWS_NUM=$(echo "$LIST" | tee | wc -l)
	i=1

       	while read LINE ; do
	  if [ -z "$LINE" ]; then
	    continue
          fi
	  echo -e "Proceeding with: ${LINE}"
	  update_repo ${LINE} 
	  progressbar $i $ROWS_NUM
	  ((i++))
	done <<< "$LIST"
}

set -e


if [ $# -eq 1 ]; then
#  git config --global credential.helper 'cache --timeout=900'
  get_dirs $1
  if [ "$ERR_NUM" -gt "0" ]; then
    echo -e "Number of errors: ${ERR_NUM}\nList of error repositories: ${ERR_LIST}"
  fi
else
  echo "Usage: `basename $0` dirname_or_regex"
  echo "Exiting..."
fi

exit 0

