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
    # perf defaults to lib64 on x86_64; conda-forge is lib everywhere
    "lib=lib"
    "LIBZSTD_DIR=$PREFIX"
    "EXTRA_CFLAGS=-I$PREFIX/include -I$PREFIX/include/traceevent"
    "PYTHON_CONFIG=python3-config"
    "NO_LIBPERL=x"
    # rustc is only used to build perf's own test workloads; pin it off so the
    # build does not vary with whatever happens to be on PATH
    "NO_RUST=1"
    "WERROR=0"
    "HOSTCC=$CC_FOR_BUILD"
    "HOSTLD=$LD"
    "HOSTAR=$AR"
    # BPF skeletons: perf lock contention, stat --bpf-counters,
    # record --off-cpu, kwork, ftrace latency -b, trace --bpf-summary
    "BUILD_BPF_SKEL=1"
    "CLANG=$BUILD_PREFIX/bin/clang"
    # libperf-jvmti.so, the JVMTI agent for Java JIT symbol resolution
    "JDIR=$BUILD_PREFIX/lib/jvm"
)

make clean
cd tools/perf
make "${ARGS[@]}"
make "${ARGS[@]}" install
