VER=1.0.13
KERNEL?=${shell uname -r}
MACH?=${shell uname -m}
MODULE=next4_module-${VER}
PWD:=${shell pwd}
KDIR=/lib/modules/${KERNEL}/build
EVENTS_DIR=${KDIR}/include/trace/events
INSTALL_DIR=/lib/modules/${KERNEL}/kernel/fs/next4
E2FSPROGS=e2fsprogs-1.41.14
E2FSPROGS_VER=1.0.13
E2FSPROGS_PATCH=${E2FSPROGS}-next4-${E2FSPROGS_VER}.patch
WEBSITE="http://next3.sf.net"

all: module utils

.PHONY: install
install: install_module install_utils

.PHONY: module
module: next4
	test -f ${EVENTS_DIR}/next4.h || \
		sudo install next4/next4_events.h ${EVENTS_DIR}/next4.h
	make -C ${KDIR} M=${PWD}/next4 modules

.PHONY: install_module
install_module:
	mkdir -p ${INSTALL_DIR}
	install -m 644 next4/next4.ko ${INSTALL_DIR}
	/sbin/depmod -a
	/sbin/modprobe next4

.PHONY: install_utils
install_utils:
	install bin/next4 /sbin
	install bin/fsck.next4 /sbin
	install bin/mkfs.next4 /sbin
	install bin/tunefs.next4 /sbin
	install bin/dumpfs.next4 /sbin
	install bin/lsattr.next4 /sbin
	install bin/chattr.next4 /sbin
	install bin/lssnap /sbin
	install bin/chsnap /sbin
	install bin/resize.next4 /sbin

.PHONY: test
test:
	grep next4 /proc/modules || /sbin/modprobe next4 || /sbin/insmod next4/next4.ko
	(test -f test.img && (./bin/tunefs.next4 -l test.img | grep UUID)) || \
		( touch test.img ; ./bin/truncate -s 4G test.img ; yes | ./bin/next4 mkfs test.img )
	mkdir -p test
	mount -t next4 | grep test || mount -t next4 test.img -o loop test
	./bin/next4 tests
	./bin/next4 umount
	/sbin/rmmod next4
	
next4: ${MODULE}.tar.gz
	tar xfz ${MODULE}.tar.gz

.PHONY: utils
utils:
	./bin/mkfs.next4 -V || make e2fsprogs
	./bin/fsck.next4 -V
	make -C bin || true

.PHONY: e2fsprogs
e2fsprogs: ${E2FSPROGS}
	make -C ${E2FSPROGS} libs
	make -C ${E2FSPROGS}/e2fsck
	install -T ${E2FSPROGS}/e2fsck/e2fsck bin/fsck.next4
	make -C ${E2FSPROGS}/misc
	install -T ${E2FSPROGS}/misc/mke2fs bin/mkfs.next4
	install -T ${E2FSPROGS}/misc/tune2fs bin/tunefs.next4
	install -T ${E2FSPROGS}/misc/dumpe2fs bin/dumpfs.next4
	install -T ${E2FSPROGS}/misc/lsattr bin/lsattr.next4
	install -T ${E2FSPROGS}/misc/chattr bin/chattr.next4
	install -T ${E2FSPROGS}/misc/lsattr bin/lssnap
	install -T ${E2FSPROGS}/misc/chattr bin/chsnap
	make -C ${E2FSPROGS}/resize
	install -T ${E2FSPROGS}/resize/resize2fs bin/resize.next4

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
	rm -rf next4 ${E2FSPROGS} test* .next4.conf

%.patch:
	@echo downloading next4 patches for kernel ${KERNEL}...
	# some wget support --trust-server-names, others don't
	@wget --trust-server-names "${WEBSITE}/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		wget "${WEBSITE}/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		(echo "Sorry, $@ is not available for kernel ${KERNEL}. Please check ${WEBSITE} for new releases." && false)

%.gz:
	@echo downloading source package $@...
	# some wget support --trust-server-names, others don't
	@wget --trust-server-names "${WEBSITE}/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		wget "${WEBSITE}/cgi-bin/download?f=$@&v=${VER}&r=${KERNEL}&m=${MACH}" || \
		(echo "Sorry, $@ is not available for kernel ${KERNEL}. Please check ${WEBSITE} for new releases." && false)


.PHONY: distclean
distclean: clean
	rm -rf *.patch *.gz


