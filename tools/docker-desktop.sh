#!/bin/bash

if [ "$machine" == "MinGw" ]; then
  choco install docker-desktop
else
  echo "Docker Desktop is not supported on $machine"
  exit 1
fi
