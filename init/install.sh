#!/bin/bash

for file in $(find $(dirname $0)/scripts -name '*.sh'); do
  echo $file;
  /bin/bash $file
done
