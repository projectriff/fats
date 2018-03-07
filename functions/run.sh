#!/bin/bash		
		
set -o errexit		
set -o nounset		
set -o pipefail		

dir=`dirname "${BASH_SOURCE[0]}"`
riffVersion=`cat $dir/../projectriff/VERSION`

for test in uppercase; do
    $dir/$test/run.sh $1 $riffVersion
done
