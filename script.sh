#!/bin/sh

set -ex

mount

try () {
	rm -f file

	dd if=/dev/urandom of=file count=13

	sync

	stat file |tee A
	if ! grep -q -E 'Blocks: (1|8) ' A
	then
		# st_blocks might already hold the right value; try again.
		return 0
	fi
	while true
	do
		sleep 1
		stat file >B
		diff -u A B
	done
}

while true
do
	try
done
