#!/bin/sh
cd "${0%/*}" && for t in test_*.sh; do ./"$t" || exit 1; done
