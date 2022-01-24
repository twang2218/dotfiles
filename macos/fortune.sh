#!/bin/bash

TMPDIR=/tmp/fortune
mkdir -p ${TMPDIR}

get_fortunes_zh() {
    (
        cd ${TMPDIR}
        curl -fSLOJ http://archive.ubuntu.com/ubuntu/pool/universe/f/fortune-zh/fortune-zh_2.97.tar.xz
        tar -Jxvf fortune-zh_2.97.tar.xz
        (
            cd fortune-zh_2.97
            make
        )
    )
}

