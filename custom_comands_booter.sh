#!/bin/bash

# laod scripts from custom_commands folder
for file in $(find ~/custom_commands -type f -name "*.sh"); do
    source $file
done