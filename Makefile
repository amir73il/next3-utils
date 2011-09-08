EXT4=ext4dev
VER=1.0.13
KERNEL?=${shell uname -r}
MACH?=${shell uname -m}
PKG=${EXT4}_snapshots-${VER}
BINPKG=${EXT4}_snapshots-${VER}-${MACH}
MODULE=${EXT4}_module
PWD:=${shell pwd}
KDIR=/lib/modules/${KERNEL}/build
EVENTS_DIR=${KDIR}/include/trace/events
INSTALL_DIR=/lib/modules/${KERNEL}/kernel/fs/${EXT4}
E2FSPROGS=e2fsprogs-1.41.14
E2FSPROGS_VER=1.0.13
E2FSPROGS_PATCH=${E2FSPROGS}_snapshots-${E2FSPROGS_VER}.patch
WEBSITE="http://next3.sf.net"

all: module utils

.PHONY: install
install: install_module install_utils

.PHONY: module
module: ${EXT4}
	sudo install -C ${EXT4}/${EXT4}_events.h ${EVENTS_DIR}/${EXT4}.h
	make -C ${KDIR} M=${PWD}/${EXT4} modules
	install -T ${EXT4}/${EXT4}.ko bin/${EXT4}.ko

.PHONY: install_module
install_module:
	mkdir -p ${INSTALL_DIR}
	install -m 644 bin/${EXT4}.ko ${INSTALL_DIR}
	/sbin/depmod -a
	/sbin/modprobe ${EXT4}

.PHONY: install_utils
install_utils:
	install bin/snapshot.${EXT4} /sbin
	install bin/fsck.${EXT4} /sbin
	install bin/mkfs.${EXT4} /sbin
	install bin/tunefs.${EXT4} /sbin
	install bin/dumpfs.${EXT4} /sbin
	install bin/lsattr.${EXT4} /sbin
	install bin/chattr.${EXT4} /sbin
	install bin/lssnap /sbin
	install bin/chsnap /sbin
	install bin/resize.${EXT4} /sbin

.PHONY: test
test:
	grep ${EXT4} /proc/modules || /sbin/modprobe ${EXT4} 2>/dev/null || /sbin/insmod bin/${EXT4}.ko
	touch test.img && mkdir -p test && ./bin/snapshot.${EXT4} config ${PWD}/test.img ${PWD}/test
	(./bin/tunefs.${EXT4} -l test.img | grep UUID) || \
		( ./bin/truncate -s 4G test.img ; yes | ./bin/snapshot.${EXT4} mkfs )
	mount -t ${EXT4} | grep '${PWD}/test' || ./bin/snapshot.${EXT4} mount
	./bin/snapshot.${EXT4} tests
	./bin/snapshot.${EXT4} umount
	/sbin/rmmod ${EXT4}
	
${EXT4}: ${MODULE}.tar.gz
	tar xfz ${MODULE}.tar.gz

.PHONY: utils
utils:
	./bin/mkfs.${EXT4} -V || make e2fsprogs
	./bin/fsck.${EXT4} -V
	make -C bin || true

.PHONY: e2fsprogs
e2fsprogs: ${E2FSPROGS}
	make -C ${E2FSPROGS} libs
	make -C ${E2FSPROGS}/e2fsck
	install -T ${E2FSPROGS}/e2fsck/e2fsck bin/fsck.${EXT4}
	make -C ${E2FSPROGS}/misc
	install -T ${E2FSPROGS}/misc/mke2fs bin/mkfs.${EXT4}
	install -T ${E2FSPROGS}/misc/tune2fs bin/tunefs.${EXT4}
	install -T ${E2FSPROGS}/misc/dumpe2fs bin/dumpfs.${EXT4}
	install -T ${E2FSPROGS}/misc/lsattr bin/lsattr.${EXT4}
	install -T ${E2FSPROGS}/misc/chattr bin/chattr.${EXT4}
	install -T ${E2FSPROGS}/misc/lsattr bin/lssnap
	install -T ${E2FSPROGS}/misc/chattr bin/chsnap
	make -C ${E2FSPROGS}/resize
	install -T ${E2FSPROGS}/resize/resize2fs bin/resize.${EXT4}
	install -T ${E2FSPROGS}/contrib/e4snapshot bin/snapshot.${EXT4}

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
	rm -rf ${EXT4} ${E2FSPROGS} test* .${EXT4}.conf

%.patch:
	@echo downloading ${EXT4} patches for kernel ${KERNEL}...
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


# clean for pre-built binaries distribution
.PHONY: distclean_bin
distclean_bin: clean
	rm -rf *.patch *.gz
	rm -f bin/${EXT4}.ko
	rm -f ${PKG}

# clean for no pre-built binaries distribution
.PHONY: distclean
distclean: distclean_bin
	make -C bin clean
	rm -f bin/*.${EXT4} bin/*snap

.PHONY:release_bin
release_bin: distclean_bin
	rm -f ${PKG}
	ln -sf ${PWD} ${PKG}
	tar cfz ../${BINPKG}.tar.gz ${PKG}/README ${PKG}/Makefile ${PKG}/docs ${PKG}/bin

.PHONY:release_nobin
release_nobin: distclean
	rm -f ${PKG}
	ln -sf ${PWD} ${PKG}
	tar cfz ../${PKG}.tar.gz ${PKG}/README ${PKG}/Makefile ${PKG}/docs ${PKG}/bin

.PHONY:release
release: release_bin release_nobin
