#!/bin/bash

set -x
# TODO remove before merging
old_dir=`pwd`
charts_dir=$fats_dir/../charts
mkdir -p $charts_dir
cd $charts_dir
git clone https://github.com/projectriff/charts.git .
echo "keda: https://raw.githubusercontent.com/sbawaska/keda/rm-clusterrole/deploy/KedaScaleController.yaml" > charts/keda/templates.yaml
sudo snap install yq
make
cd $old_dir
