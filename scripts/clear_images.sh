#!/bin/bash

for image in $(/k3s/data/current/bin/crictl images | awk '{print $3}'); do 
    /k3s/data/current/bin/crictl rmi $image;
done
