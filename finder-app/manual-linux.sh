#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

N=$(expr $(nproc) / 2)
N=$(( N > 4 ? 4 : N ))

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    ## required packages (not yet installed in my system)
    # sudo apt install flex bison

    echo "cleaning"
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper
    echo "making defconfig"
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig

    echo "making Image"
    if ! make -j$N ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all; then
        ## /usr/bin/ld: scripts/dtc/dtc-parser.tab.o:(.bss+0x20): multiple definition of `yylloc'; scripts/dtc/dtc-lexer.lex.o:(.bss+0x0): first defined here
        echo "patching bug in dtc and retrying"
        sed -i 's/^YYLTYPE yylloc;/extern YYLTYPE yylloc;/' scripts/dtc/dtc-lexer.lex.c
        make -j$N ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all
    fi

    echo "making modules"
    make -j$N ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs

    echo "done building kernel"
    ls -al arch/arm64/boot/
fi

echo "Adding the Image in outdir"
cp -v ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -f "${OUTDIR}/busybox/bin/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}

    # TODO:  Configure busybox

    echo "cleaning"
    make distclean

    echo "making defconfig"
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig

    echo "building busybox"
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE}
else
    cd busybox
fi

if ! test -f "${OUTDIR}/rootfs/bin/busybox"; then
    echo "installing busybox"
    make CONFIG_PREFIX="${OUTDIR}/busybox" ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} install

    echo "Library dependencies"
    ${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
    ${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

    for dir in bin sbin usr/bin usr/sbin; do
        cp -a ${OUTDIR}/busybox/${dir}/* ${OUTDIR}/rootfs/${dir}
    done
fi

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -Lv "$SYSROOT"/lib/ld-linux-aarch64.* "${OUTDIR}/rootfs/lib"
cp -Lv "$SYSROOT"/lib64/libm.so.* "${OUTDIR}/rootfs/lib64"
cp -Lv "$SYSROOT"/lib64/libresolv.so.* "${OUTDIR}/rootfs/lib64"
cp -Lv "$SYSROOT"/lib64/libc.so.* "${OUTDIR}/rootfs/lib64"

# TODO: Make device nodes
echo "making device nodes"
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# (juan)...
# create /dev/random
sudo mknod -m 444 dev/random c 1 8
sudo mknod -m 444 dev/urandom c 1 9
# create /dev/ttyS0
sudo mknod -m 666 dev/ttyS0 c 4 64
# create /dev/tty
sudo mknod -m 666 dev/tty c 5 0

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -av ${FINDER_APP_DIR}/{writer,finder.sh,finder-test.sh,autorun-qemu.sh} ${OUTDIR}/rootfs/home/
mkdir -pv ${OUTDIR}/rootfs/home/conf
cp -v ${FINDER_APP_DIR}/conf/{assignment.txt,username.txt} ${OUTDIR}/rootfs/home/conf/

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip initramfs.cpio
