set -eu

unset ARCH

# several sub-makes (e.g. the bundled libbpf) override CFLAGS/EXTRA_CFLAGS,
# losing the conda include/lib paths; CPATH and LIBRARY_PATH are honoured by
# the compiler driver itself so they survive any make-level clobbering
export CPATH="$PREFIX/include"
export LIBRARY_PATH="$PREFIX/lib"

# perf requires libtraceevent, which was removed from the kernel tree in 6.2
# and is not packaged on conda-forge. Build it here and link it statically so
# nothing extra ships in the package. Its BTF support needs newer UAPI headers
# than the sysroot provides, so install this kernel's headers for it to use.
make -C "$SRC_DIR" -j"$CPU_COUNT" HOSTCC="$CC_FOR_BUILD" \
    headers_install INSTALL_HDR_PATH="$SRC_DIR/uapi-headers"
make -C "$SRC_DIR/libtraceevent" -j"$CPU_COUNT" \
    prefix="$PREFIX" \
    libdir_relative=lib \
    pkgconfig_dir="$PREFIX/lib/pkgconfig" \
    LDCONFIG=false \
    EXTRA_CFLAGS="${CFLAGS} -I$SRC_DIR/uapi-headers/include" \
    install_libs
# only keep the static library so perf cannot link the shared one
rm "$PREFIX"/lib/libtraceevent.so*
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

# drop the vendored libtraceevent build artifacts so they are not packaged
rm -r "$PREFIX/include/traceevent"
rm "$PREFIX/lib/libtraceevent.a" "$PREFIX/lib/pkgconfig/libtraceevent.pc"
