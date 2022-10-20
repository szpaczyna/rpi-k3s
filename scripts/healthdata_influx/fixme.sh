#!/bin/bash

patch < patch.txt
sed -i 's/startDate/endDate/2' export.xml
