# Makefile for generating Next3 patches
# Amir Goldstein <amir73il@users.sf.net>, 2010
#
# 

# configuration parameters:
# location of work dir with non-stripped next3 sources
SRC?=..
# location of release dir for patches
RELEASE?=~
KERNEL?=2.6.31
# location of kernel archive
LINUX_PKG?=../../kernel/${KERNEL}
# location of e2fsprogs archive
E2FS_PKG?=../../pkg

ifeq ($(KERNEL),2.6.31)
LINUX?=linux-2.6.31.11
endif
ifeq ($(KERNEL),2.6.32)
LINUX=linux-2.6.32.12
endif
ifeq ($(KERNEL),2.6.27)
LINUX=linux-2.6.27.7
endif

# xlate "X0" -> "X", "0" -> ""
ID0?=${shell (echo ${ID}|tr -d 0)}
SUFFIX=${shell (test _${ID} = _0 || test _${ID} = _00 || echo ${KEY})}

# patches signed-off-by
SIGNATURE=Amir Goldstein <amir73il@users.sf.net>
SIGNEDOFF=Signed-off-by: ${SIGNATURE}
DELIMITER="--------------------------------------------------------------------------------"

#N3_VERSION=1.0.12-rc1
N3_VERSION?=${DATE}
N3_PKGNAME=next3-${N3_VERSION}
N3_TARBALL=${N3_PKGNAME}.tar.gz
N3_RELEASE=${RELEASE}/${N3_PKGNAME}
N3_SUBTARBALL=next3_snapshot-${N3_VERSION}_patches.tar.gz
N3_PATCH=next3_snapshot-${N3_VERSION}.patch
N3_SUBPATCH=next3_snapshot_${SUFFIX}.patch
DATE=${shell date +%d%m%y}
N3_WIKI=../docs/wiki/Next3_snapshot_patches
N3_BASEPATCH=${LINUX}-next3_fs.patch
ORIG=origin
BASE=branch
REBASE=../rebase
UPDATE=./update_files.sh
STRIP=./strip_ifdefs
SRC_PREV=head^
SRC_HEAD=head
PREV=HEAD^
HEAD=HEAD

CFLAGS=-g

INC=${LINUX}/include/linux
INC_FILES=${INC}/jbd.h ${INC}/journal-head.h ${INC}/magic.h
FS=${LINUX}/fs
JBD=${FS}/jbd
FS_FILES=${FS}/Makefile ${FS}/Kconfig ${JBD}/journal.c
N3=${LINUX}/fs/next3
MOD_FILES=${N3}/Kconfig ${N3}/Makefile \
	  ${N3}/balloc.c ${N3}/file.c ${N3}/ialloc.c ${N3}/inode.c ${N3}/ioctl.c \
	  ${N3}/namei.c ${N3}/next3_jbd.c ${N3}/resize.c ${N3}/super.c ${N3}/xattr.c \
	  ${N3}/next3.h ${N3}/next3_i.h ${N3}/next3_jbd.h ${N3}/next3_sb.h
NEW_FILES=${N3}/buffer.c ${N3}/snapshot.c ${N3}/snapshot_ctl.c ${N3}/snapshot.h \
	  ${N3}/snapshot_debug.c ${N3}/snapshot_debug.h
OLD_FILES=${N3}/acl.c ${N3}/acl.h ${N3}/bitmap.c ${N3}/dir.c ${N3}/fsync.c \
	  ${N3}/hash.c ${N3}/namei.h ${N3}/symlink.c ${N3}/xattr.h \
	  ${N3}/xattr_security.c ${N3}/xattr_trusted.c ${N3}/xattr_user.c
E3=${LINUX}/fs/ext3
E3_INC_FILES=${INC}/ext3_fs.h ${INC}/ext3_fs_i.h ${INC}/ext3_jbd.h ${INC}/ext3_fs_sb.h

N3_FILES=${INC_FILES} ${FS_FILES} ${JBD_FILES} ${MOD_FILES} ${NEW_FILES} ${OLD_FILES}

BIN=../bin
DOC=../docs
BIN_FILES=${BIN}/snapshot
DOC_FILES=${DOC}/README ${DOC}/COPYING ${DOC}/INSTALL ${DOC}/HOWTO ${DOC}/CHANGELOG \
	  ${DOC}/INDEX ${DOC}/BUGS ${DOC}/TODO

all: next3

clean: clean_next3 clean_e2fs
	rm -f a b files series

distclean: clean
	rm -rf ${ORIG} ${BASE}

.PHONY: next3 next3_fs next3_snapshot wiki release
next3: ${STRIP} rotate_dirs ${BASE}/${LINUX} ${N3_FILES} ${N3_PATCH}~
	@test -z ${ID} || diff -Nuarp ${SRC_PREV} ${SRC_HEAD} > ${N3_SUBPATCH}+ || test 1 = 1
	@test -z ${ID} || (rm -f a b ; ln -sf ${PREV}/${LINUX} a ; ln -sf ${HEAD}/${LINUX} b)
	@test -z ${ID} || (diff -Nuarp a b >> ${N3_SUBPATCH} ; \
			((echo -n ${ID} ${N3_SUBPATCH} ; \
			(diffstat ${N3_SUBPATCH}|tail -n 1)) >> next3_series))
	@diff -Nuarp ${BASE}/${LINUX} ${SRC_PREV}/${LINUX} > _${N3_PATCH}+ || test 1 = 1
	@(cat ${N3_PATCH}~ ; echo "${SIGNEDOFF}" ; echo ; echo ${DELIMITER}) > _${N3_PATCH}
	@rm -f a b ; ln -sf ${BASE}/${LINUX} a ; ln -sf ${PREV}/${LINUX} b
	@diff -Nuarp a b >> _${N3_PATCH} || test 1 = 1
	@test ! -z ${KEY} || cp _${N3_PATCH}+ ${N3_PATCH}+
	@test _${KEY} != _HEAD || cp _${N3_PATCH} ${N3_PATCH}
	@test _${ID} != _00 || (cp _${N3_PATCH} ${N3_SUBPATCH} ; \
				cp ${N3_PATCH}~ ${N3_SUBPATCH}~)
	diffstat _${N3_PATCH}|tail -n 1

${N3_PATCH}~:
	(echo "next3_snapshot.patch adds snapshot support to Next3 (after it was cloned from Ext3)." ; echo ) > $@
	(echo "The next3_snapshot patch aggregates all next3_snapshot_X sub-patches and next3_snapshot_X_Y sub-sub-patches." ; echo ) >> $@

release:
	rm -rf ${N3_RELEASE}
	mkdir -p ${N3_RELEASE}/scripts
	cp ${DOC_FILES} ${N3_RELEASE}
	cp ${BIN_FILES} ${N3_RELEASE}/scripts
	mkdir -p ${N3_RELEASE}/patches
	cp ${E2FS_PATCH} ${N3_RELEASE}/patches
	cp ${N3_BASEPATCH} ${N3_RELEASE}/patches
	cp ${N3_PATCH} ${N3_RELEASE}/patches
	cd ${RELEASE} ; tar cfz ${N3_TARBALL} ${N3_PKGNAME}

${N3_BASEPATCH}~:
	@echo "Adds a cloned Next3 file system to the kernel." > $@
	@echo >> $@
	@echo "Next3 was cloned from Ext3 in ${LINUX}, but this patch may be applied to other kernel versions." >> $@ 
	@echo "next3_snapshot-1.0.y.patch applies on top of this patch." >> $@
	@echo >> $@

next3_fs: ${BASE}/${LINUX} ${N3_BASEPATCH}~
	@# rebase from sources
	@test ! -d ${REBASE}/${LINUX} || ${UPDATE} ${REBASE}/${LINUX} ${BASE}/${LINUX}
	@# create built-in patch (exclude fs/next3 files)
	@rm -f a b ; ln -sf ${ORIG}/${LINUX} a ; ln -sf ${BASE}/${LINUX} b
	@mkdir -p ${ORIG}/fs ${BASE}/fs
	@mv ${BASE}/${LINUX}/fs/next3 ${BASE}/fs
	@diff -Nuarp a b > $@.built-in.patch || cp $@.built-in.patch ${LINUX_PKG}
	@# create module patch (only fs/next3 files)
	@rm -f a b ; ln -sf ${ORIG} a ; ln -sf ${BASE} b
	@diff -Nuarp a/fs b/fs > $@.module.patch || cp $@.module.patch ${LINUX_PKG}
	@mv ${BASE}/fs/next3 ${BASE}/${LINUX}/fs
	@rm -rf a b ${ORIG}/fs ${BASE}/fs
	@# create full base+rebase/built-in+module patch
	@(cat ${N3_BASEPATCH}~ ; echo "${SIGNEDOFF}" ; echo ; echo ${DELIMITER}) > ${N3_BASEPATCH}
	@rm -f a b ; ln -sf ${ORIG}/${LINUX} a ; ln -sf ${BASE}/${LINUX} b
	@diff -Nuarp a b >> ${N3_BASEPATCH} || test 1 = 1

next3_snapshot: next3_fs next3
	make KEY=exclude_files
	make KEY=file_goal
	make KEY=HEAD
	@rm -f a b ; ln -sf ${BASE}/${LINUX} a ; ln -sf ${PREV}/${LINUX} b
	@mkdir -p ${PREV}/fs ${BASE}/fs
	@mv ${PREV}/${LINUX}/fs/next3 ${PREV}/fs ; mv ${BASE}/${LINUX}/fs/next3 ${BASE}/fs
	@diff -Nuarp a b > $@.built-in.patch || cp $@.built-in.patch ${LINUX_PKG}
	@rm -f a b ; ln -sf ${BASE} a ; ln -sf ${PREV} b
	@diff -Nuarp a/fs b/fs > $@.module.patch || cp $@.module.patch ${LINUX_PKG}
	@mv ${PREV}/fs/next3 ${PREV}/${LINUX}/fs ; mv ${BASE}/fs/next3 ${BASE}/${LINUX}/fs
	@rm -rf a b ${PREV}/fs ${BASE}/fs

next3_series: next3_fs next3
	make KEY=exclude_files
	make KEY=file_goal
	make KEY=HEAD
	@rm -f $@
	make ID=92 KEY=cleanup_merge
	make ID=91 KEY=cleanup_shrink
	make ID=90 KEY=cleanup
	make ID=83 KEY=exclude_bitmap
	make ID=82 KEY=exclude_inode_old
	make ID=81 KEY=exclude_inode
	make ID=80 KEY=exclude
	make ID=73 KEY=race_read
	make ID=72 KEY=race_cow
	make ID=71 KEY=race_bitmap
	make ID=70 KEY=race
	make ID=61 KEY=list_read
	make ID=60 KEY=list
	make ID=56 KEY=journal_trace
	make ID=55 KEY=journal_cache
	make ID=54 KEY=journal_bypass
	make ID=53 KEY=journal_release
	make ID=52 KEY=journal_credits
	make ID=51 KEY=journal_error
	make ID=50 KEY=journal
	make ID=44 KEY=ctl_dump
	make ID=43 KEY=ctl_reserve
	make ID=42 KEY=ctl_fix
	make ID=41 KEY=ctl_init
	make ID=40 KEY=ctl
	make ID=33 KEY=block_bitmap
	make ID=32 KEY=block_move
	make ID=31 KEY=block_cow
	make ID=30 KEY=block
	make ID=25 KEY=file_old
	make ID=24 KEY=file_huge
	make ID=23 KEY=file_store
	make ID=22 KEY=file_perm
	make ID=21 KEY=file_read
	make ID=20 KEY=file
	make ID=13 KEY=hooks_data
	make ID=12 KEY=hooks_delete
	make ID=11 KEY=hooks_jbd
	make ID=10 KEY=hooks
	make ID=02 KEY=debug
	make ID=01 KEY=main
	make ID=00 KEY=rebase
	@sort next3_series | ( while read id patch files info ; do (test _$$files != _0 || test _$$id == _00) \
								&& echo $$patch ; done ) > series
	@echo series > files
	@cat series >> files
	@tar cfz ${N3_SUBTARBALL} --files-from files
	cp ${N3_SUBTARBALL} ${RELEASE}

wiki:
	@sort next3_series | ( while read id patch info ; do cat $$patch~ ; done ) > ${N3_WIKI}

${BASE}/${LINUX}: next3.sed next3_include.sed next3_ext4.sed
	rm -rf ${LINUX} ${BASE} ${ORIG}
	mkdir -p ${BASE} ${ORIG}
	tar xfj ${LINUX_PKG}/${LINUX}.tar.bz2 ${INC_FILES} ${FS_FILES} ${E3} ${E3_INC_FILES}
	cp -a ${LINUX} ${LINUX}.ext3
	rm -rf ${E3}
	rm -rf ${E3_INC_FILES}
	mv ${LINUX} ${ORIG}
	mv ${LINUX}.ext3 ${LINUX}
	# clone next3 files from ext3
	mv ${E3} ${N3}
	mv ${E3_INC_FILES} ${N3}
	touch ${N3}/Kconfig
	sed -i -f next3.sed ${N3}/*
	# rename ext3_* files
	mv ${N3}/ext3_fs.h ${N3}/next3.h
	mv ${N3}/ext3_fs_i.h ${N3}/next3_i.h
	mv ${N3}/ext3_fs_sb.h ${N3}/next3_sb.h
	mv ${N3}/ext3_jbd.h ${N3}/next3_jbd.h
	mv ${N3}/ext3_jbd.c ${N3}/next3_jbd.c
	sed -i -f next3_include.sed ${N3}/*
	# add next3 to linux file systems
	grep -v EXT4 ${INC}/magic.h > x
	diff x ${INC}/magic.h | sed -f next3_ext4.sed > y
	patch ${INC}/magic.h < y
	grep -v EXT4 ${FS}/Makefile > x
	diff x ${FS}/Makefile | sed -f next3_ext4.sed > y
	patch ${FS}/Makefile < y
	grep -v fs.ext4 ${FS}/Kconfig > x
	diff x ${FS}/Kconfig | sed -f next3_ext4.sed > y
	patch ${FS}/Kconfig < y
	rm x y
	mv ${LINUX} ${BASE}

next3.sed:
	echo "s/ext3/next3/g" > $@
	echo "s/Ext3/Next3/g" >> $@
	echo "s/EXT3/NEXT3/g" >> $@
	echo "s/__FUNCTION__/__func__/g" >> $@

next3_ext4.sed:
	echo "s/ext4/next3/g" > $@
	echo "s/EXT4/NEXT3/g" >> $@

next3_include.sed:
	echo "s/linux\/include\/linux\/next3_fs\.h/linux\/fs\/next3\/next3\.h/g" > $@
	echo "s/linux\/include\/linux\/next3_fs_i\.h/linux\/fs\/next3\/next3_i\.h/g" >> $@
	echo "s/linux\/include\/linux\/next3_fs_sb\.h/linux\/fs\/next3\/next3_sb\.h/g" >> $@
	echo "s/linux\/include\/linux\/next3_jbd\.h/linux\/fs\/next3\/next3_jbd\.h/g" >> $@
	echo "s/_LINUX_NEXT3_FS_H/_LINUX_NEXT3_H/g" >> $@
	echo "s/_LINUX_NEXT3_FS_I/_LINUX_NEXT3_I/g" >> $@
	echo "s/_LINUX_NEXT3_FS_SB/_LINUX_NEXT3_SB/g" >> $@
	echo "s/<linux\/next3_fs\.h>/\"next3\.h\"/g" >> $@
	echo "s/<linux\/next3_fs_i\.h>/\"next3_i\.h\"/g" >> $@
	echo "s/<linux\/next3_fs_sb\.h>/\"next3_sb\.h\"/g" >> $@
	echo "s/<linux\/next3_jbd\.h>/\"next3_jbd\.h\"/g" >> $@

.PHONY: rotate_dirs
rotate_dirs:
	@test ! -e ${SRC_HEAD} || rm -rf ${SRC_HEAD}
	@test ! -e ${SRC_PREV} || mv ${SRC_PREV} ${SRC_HEAD}
	@mkdir -p ${SRC_PREV}/{${INC},${N3},${JBD},${E2FS}/{debugfs,misc,resize},${FSCK},${E2LIB}/{e2p,ext2fs}}
	@mkdir -p ${SRC_HEAD}/{${INC},${N3},${JBD},${E2FS}/{debugfs,misc,resize},${FSCK},${E2LIB}/{e2p,ext2fs}}
	@test ! -e ${HEAD} || rm -rf ${HEAD}
	@test ! -e ${PREV} || mv ${PREV} ${HEAD}
	@mkdir -p ${PREV}/{${INC},${N3},${JBD},${E2FS}/{debugfs,misc,resize},${FSCK},${E2LIB}/{e2p,ext2fs}}
	@mkdir -p ${HEAD}/{${INC},${N3},${JBD},${E2FS}/{debugfs,misc,resize},${FSCK},${E2LIB}/{e2p,ext2fs}}

${INC}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${JBD}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${N3}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${N3}/Kconfig:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ((${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY} > ${N3_SUBPATCH}~) && \
			(cat ${N3_SUBPATCH}~ ; echo "${SIGNEDOFF}" ; echo ; echo ${DELIMITER}) > ${N3_SUBPATCH})
	@test -z ${KEY} || test ! -z ${ID} || rm ${N3_SUBPATCH} ${N3_SUBPATCH}~
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${INC}/magic.h: ${BASE}/${INC}/magic.h
	@cp $< ${SRC_PREV}/$@ ; cp $< ${PREV}/$@

${FS}/Kconfig: ${BASE}/${FS}/Kconfig
	@cp $< ${SRC_PREV}/$@ ; cp $< ${PREV}/$@

${FS}/Makefile: ${BASE}/${FS}/Makefile
	@cp $< ${SRC_PREV}/$@ ; cp $< ${PREV}/$@

clean_next3:
	rm -rf ${STRIP} ${LINUX}* next3* *.patch*
	rm -rf ${SRC_HEAD} ${SRC_PREV} ${HEAD} ${PREV}

#
# e2fsprogs patch
#
E2FS=e2fsprogs-1.41.9
E2FS_PATCH=${E2FS}-next3-${N3_VERSION}.patch
E2FS_SUBTARBALL=${E2FS}-next3-${N3_VERSION}_patches.tar.gz
E2FS_SUBPATCH=e2fs_next3_${SUFFIX}.patch

E2LIB=${E2FS}/lib
E2LIB_FILES=${E2LIB}/e2p/pf.c ${E2LIB}/e2p/feature.c ${E2LIB}/e2p/ls.c ${E2LIB}/e2p/e2p.h \
	${E2LIB}/ext2fs/res_gdt.c ${E2LIB}/ext2fs/swapfs.c ${E2LIB}/ext2fs/mkjournal.c \
	${E2LIB}/ext2fs/block.c ${E2LIB}/ext2fs/i_block.c ${E2LIB}/ext2fs/bmap.c ${E2LIB}/ext2fs/rw_bitmaps.c \
	${E2LIB}/ext2fs/openfs.c ${E2LIB}/ext2fs/ext2fs.h ${E2LIB}/ext2fs/ext2_fs.h
FSCK=${E2FS}/e2fsck
FSCK_FILES=${FSCK}/problem.c ${FSCK}/unix.c ${FSCK}/super.c ${FSCK}/rehash.c ${FSCK}/journal.c \
	${FSCK}/pass1.c ${FSCK}/pass5.c ${FSCK}/problem.h ${FSCK}/e2fsck.h
MISC_FILES=${E2FS}/misc/dumpe2fs.c ${E2FS}/misc/mke2fs.c ${E2FS}/misc/tune2fs.c ${E2FS}/misc/util.c \
	${E2FS}/misc/lsattr.c ${E2FS}/misc/chattr.c ${E2FS}/misc/e2image.c \
	${E2FS}/resize/main.c ${E2FS}/resize/resize2fs.c ${E2FS}/debugfs/set_fields.c 
E2FS_FILES=${E2LIB_FILES} ${FSCK_FILES} ${MISC_FILES} ${E2FS}/version.h 

.PHONY: e2fs e2fs_clean
e2fs: ${STRIP} rotate_dirs ${ORIG}/${E2FS} ${E2FS_FILES} ${E2FS}/Sconfig ${E2FS_PATCH}~
	@test -z ${ID0} || diff -Nuarp ${SRC_PREV} ${SRC_HEAD} > ${E2FS_SUBPATCH}+ || test 1 = 1
	@test -z ${ID0} || (rm -f a b ; ln -sf ${PREV}/${E2FS} a ; ln -sf ${HEAD}/${E2FS} b)
	@test -z ${ID0} || (diff -Nuarp a b >> ${E2FS_SUBPATCH} ; \
			((echo -n ${ID} ${E2FS_SUBPATCH} ; \
			(diffstat ${E2FS_SUBPATCH}|tail -n 1)) >> e2fs_series))
	@diff -Nuarp ${ORIG}/${E2FS} ${SRC_PREV}/${E2FS} > _${E2FS_PATCH}+ || test 1 = 1
	@rm -f a b ; ln -sf ${ORIG}/${E2FS} a ; ln -sf ${PREV}/${E2FS} b
	@diff -Nuarp a b > _${E2FS_PATCH} || test 1 = 1
	@test ! -z ${KEY} || cp _${E2FS_PATCH}+ ${E2FS_PATCH}+
	@test _${KEY} != _HEAD || cat ${E2FS_PATCH}~ _${E2FS_PATCH} > ${E2FS_PATCH}
	@test _${ID} != _0 || cat ${E2FS_SUBPATCH}~ _${E2FS_PATCH} > ${E2FS_SUBPATCH}
	diffstat _${E2FS_PATCH}|tail -n 1

${E2FS_PATCH}~:
	@echo "Adds Next3 snapshot awareness to e2fsprogs." > $@
	@echo >> $@
	@echo "There are no snapshot COW operations during offline processing," >> $@
	@echo "only restrictions on changing a file system with snapshots offline." >> $@
	@echo "Adds the compatible features 'exclude_inode' and 'big_journal'." >> $@
	@echo "Adds the ro-compatible features 'has_snapshot','is_snapshot','fix_exclude','fix_snapshot'." >> $@
	@echo "chattr is used to control Next3 snapshots and lsattr is used to display snapshots status." >> $@
	@echo >> $@
	@echo "${SIGNEDOFF}" >> $@
	@echo >> $@
	@echo "${DELIMITER}" >> $@

${ORIG}/${E2FS}:
	@mkdir -p ${ORIG}
	@rm -rf ${ORIG}/${E2FS}
	@tar xkfz ${E2FS_PKG}/${E2FS}.tar.gz -C ${ORIG} ${E2FS_FILES}

e2fs_next3: ${ORIG}/${E2FS} e2fs
	make e2fs KEY=HEAD
	@diff -Nuarp a b > $@.patch || test 1 = 1

e2fs_series: ${ORIG}/${E2FS} e2fs
	make e2fs KEY=HEAD
	@rm -f $@
	make e2fs ID=c KEY=on_disk_migrate
	make e2fs ID=b KEY=message_buffer
	make e2fs ID=a KEY=huge_snapshot
	make e2fs ID=9 KEY=fix_snapshot
	make e2fs ID=8 KEY=check_list
	make e2fs ID=7 KEY=exclude_bitmap
	make e2fs ID=6 KEY=cleanup
	make e2fs ID=5 KEY=has_snapshot
	make e2fs ID=4 KEY=ctl
	make e2fs ID=3 KEY=exclude_inode
	make e2fs ID=2 KEY=big_journal
	make e2fs ID=1 KEY=on_disk
	make e2fs ID=0 KEY=rebase
	@sort e2fs_series | ( while read id patch info ; do echo $$patch ; done ) > series
	@echo series > files
	@cat series >> files
	@tar cfz ${E2FS_SUBTARBALL} --files-from files
	@cp ${E2FS_SUBTARBALL} ${RELEASE}

${E2FS}/version.h:
	@cp ${SRC}/$@ ${SRC_PREV}/$@ ; cp ${SRC}/$@ ${PREV}/$@

${E2FS}/Sconfig:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ((${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY} > ${E2FS_SUBPATCH}~) && \
		(cat ${E2FS_SUBPATCH}~ ; echo "${SIGNEDOFF}") > ${E2FS_SUBPATCH} && \
		cp ${E2FS_SUBPATCH} ${E2FS_SUBPATCH}~)
	@cp ${SRC_PREV}/$@ ${SRC_HEAD}/$@

${E2FS}/debugfs/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${E2FS}/misc/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${E2FS}/resize/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${E2LIB}/e2p/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${E2LIB}/ext2fs/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

${FSCK}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@ snapshot y

clean_e2fs:
	rm -rf e2fs* *_e2fs* */e2fs*

