VER=1.0.13-rc4
KERNEL?=${shell uname -r}
MACH?=${shell uname -m}
BASE_PATCH=next3_fs.module.patch
SNAPSHOT_PATCH=next3_snapshot.module.patch
PWD:=${shell pwd}
KDIR=/lib/modules/${KERNEL}/build
INSTALL_DIR=/lib/modules/${KERNEL}/fs/next3
E2FSPROGS=e2fsprogs-1.41.9
E2FSPROGS_VER=1.0.12
E2FSPROGS_PATCH=${E2FSPROGS}-next3-${E2FSPROGS_VER}.patch

all: module utils

.PHONY: module
module: next3
	make -C ${KDIR} M=${PWD}/next3 modules

.PHONY: install
install:
	mkdir -p ${INSTALL_DIR}
	install -m 644 next3/next3.ko ${INSTALL_DIR}
	/sbin/depmod -a
	/sbin/modprobe next3
	install bin/next3 /sbin
	install bin/fsck.next3 /sbin
	install bin/mkfs.next3 /sbin
	install bin/tunefs.next3 /sbin
	install bin/lsattr.next3 /sbin
	install bin/chattr.next3 /sbin

.PHONY: test
test:
	grep next3 /proc/modules || /sbin/insmod next3/next3.ko
	(test -f test.img && (bin/tunefs.next3 -l test.img | grep UUID)) || ( touch test.img ; yes | bin/mkfs.next3 test.img 1048576 )
	mkdir -p test
	mount -t next3 | grep test || mount -t next3 test.img -o loop test
	bin/next3 tests
	bin/next3 umount
	/sbin/rmmod next3
	
next3: ${BASE_PATCH} ${SNAPSHOT_PATCH}
	@patch -v || echo "Please install the patch utility, i.e.: sudo apt-get install patch"
	patch -p2 < ${BASE_PATCH}
	patch -p2 < ${SNAPSHOT_PATCH}

.PHONY: utils
utils:
	bin/mkfs.next3 -V || make e2fsprogs
	bin/fsck.next3 -V

.PHONY: e2fsprogs
e2fsprogs: ${E2FSPROGS}
	make -C ${E2FSPROGS} libs
	make -C ${E2FSPROGS}/e2fsck
	install -T ${E2FSPROGS}/e2fsck/e2fsck bin/fsck.next3
	make -C ${E2FSPROGS}/misc
	install -T ${E2FSPROGS}/misc/mke2fs bin/mkfs.next3
	install -T ${E2FSPROGS}/misc/tune2fs bin/tunefs.next3
	install -T ${E2FSPROGS}/misc/lsattr bin/lsattr.next3
	install -T ${E2FSPROGS}/misc/chattr bin/chattr.next3

${E2FSPROGS}: ${E2FSPROGS}.tar.gz ${E2FSPROGS_PATCH}
	@patch -v || echo "Please install the patch utility, i.e.: sudo apt-get install patch"
	tar xfz ${E2FSPROGS}.tar.gz
	cat ${E2FSPROGS_PATCH} | patch -p1 -d $@
	cd ${E2FSPROGS} ; ./configure \
	  --disable-jbd-debug \
	  --disable-blkid-debug \
	  --disable-testio-debug \
	  --disable-debugfs \
	  --disable-imager \
	  --disable-fsck \
	  --disable-e2initrd-helper \
	  --disable-tls \
	  --disable-uuidd \
	  --disable-nls \
	  --disable-rpath

.PHONY: clean
clean:
	rm -rf next3 ${E2FSPROGS} test* .next3.conf

%.patch:
	@echo downloading next3 patches for kernel ${KERNEL}...
	# some wget support --trust-server-names, others don't
	@wget --trust-server-names "http://next3.sf.net/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		wget "http://next3.sf.net/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		(echo "Sorry, $@ is not available for kernel ${KERNEL}. Please check http://next3.sf.net for new releases." && false)

%.gz:
	@echo downloading source package $@...
	# some wget support --trust-server-names, others don't
	@wget --trust-server-names "http://next3.sf.net/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		wget "http://next3.sf.net/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		(echo "Sorry, $@ is not available for kernel ${KERNEL}. Please check http://next3.sf.net for new releases." && false)


.PHONY: distclean
distclean: clean
	rm -rf *.patch *.gz


