#!/bin/sh


export TMPDIR=~/tmp

./aports/scripts/mkimage.sh \
	--tag edge \
	--outdir ~/iso \
	--arch aarch64 \
	--repository https://dl-cdn.alpinelinux.org/alpine/edge/main \
	--repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
	--profile toasterimg
