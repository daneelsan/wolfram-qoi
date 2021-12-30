#!/usr/bin/env bash

SCRIPTDIR="$(cd -P "$(dirname "$0")" && pwd)"
PACLETDIR="$(dirname ${SCRIPTDIR})"
QOIDIR="${PACLETDIR}/qoi"

QOIREPOURL="https://github.com/phoboslab/qoi.git"

echo "Clonning repository: ${QOIREPOURL}..."
git clone ${QOIREPOURL} ${QOIDIR}
[ $? -eq 0 ] && echo "Clonning succeeded" || echo "Cloning failed"

