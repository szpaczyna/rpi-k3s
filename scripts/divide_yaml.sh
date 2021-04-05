#!/bin/bash
awk '/^..name:/{file=$2 ".yaml"} !/^-/{temp=temp $0 "\n"} /^-/{print temp>file; close(file); temp=""}' "$1"
