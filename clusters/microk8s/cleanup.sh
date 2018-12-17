#!/bin/bash

snap unalias kubectl
snap unalias docker

microk8s.reset
snap remove microk8s
