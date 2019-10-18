#!/bin/bash

# TODO remove before merging

cd ..
git clone https://github.com/projectriff/charts.git
cd charts
echo "keda: https://raw.githubusercontent.com/sbawaska/keda/rm-clusterrole/deploy/KedaScaleController.yaml" > charts/keda/templates.yaml
sudo snap install yq
make
cd ../fats