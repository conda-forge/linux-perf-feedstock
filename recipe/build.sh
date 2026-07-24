set -eu

unset ARCH

# several sub-makes (e.g. the bundled libbpf) override CFLAGS/EXTRA_CFLAGS,
# losing the conda include/lib paths; CPATH and LIBRARY_PATH are honoured by
# the compiler driver itself so they survive any make-level clobbering
export CPATH="$PREFIX/include"
export LIBRARY_PATH="$PREFIX/lib"

# perf discovers libtraceevent via pkg-config
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

ARGS=(
    "-fMakefile.perf"
    "VF=x"
    "-j$CPU_COUNT"
    "prefix=$PREFIX"
    "LIBZSTD_DIR=$PREFIX"
    "EXTRA_CFLAGS=-I$PREFIX/include -I$PREFIX/include/traceevent"
    "PYTHON_CONFIG=python3-config"
    "NO_LIBPERL=x"
    "WERROR=0"
    "HOSTCC=$CC_FOR_BUILD"
    "HOSTLD=$LD"
    "HOSTAR=$AR"
)

make clean
cd tools/perf
make "${ARGS[@]}"
make "${ARGS[@]}" install
