#!/bin/bash

pwd       # -> /home/peter/github/Projects

find . -type f -name '*Zone.Identifier' | wc -l
echo "==="
find . -type f -name '*Zone.Identifier' | sed 's|/[^/]*$||' | sort | uniq -c | sort -nr


# find . -type f -name '*Zone.Identifier' -delete