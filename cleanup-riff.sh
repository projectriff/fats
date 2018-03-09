#!/bin/bash

source ./util.sh

helm delete --purge control
helm delete --purge transport
