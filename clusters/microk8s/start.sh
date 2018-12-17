#!/bin/bash

sudo snap install microk8s --channel=1.12/stable --classic
microk8s.status --wait-ready

snap alias microk8s.kubectl kubectl
snap alias microk8s.docker docker
