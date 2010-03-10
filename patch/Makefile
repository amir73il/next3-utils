# Makefile for generating Next3 patches
# Amir Goldstein <amir@ctera.com>, 2010
#
# 

# configuration parameters:
# location of work dir with non-stripped next3 sources
SRC?=..
# location of release dir for patches
RELEASE?=~
# location of kernel archive
LINUX_PKG?=../../kernel/2.6.31
# location of e2fsprogs archive
E2FS_PKG?=../../pkg

# xlate "X0" -> "X", "XY" -> ""
ID0?=${shell (echo ${ID}|grep 0|tr -d 0)}

# patches signed-off-by
SIGNATURE=Amir Goldstein <amir73il@users.sf.net>

N3_PATCH=next3_snapshot.patch
N3_BASEPATCH=next3_fs.patch
N3_SUBPATCH=${ID}_next3_snapshot_${KEY}.patch
N3_ID0PATCH=${ID0}_next3_snapshot_${KEY}.patch
DATE=${shell date +%d%m%y}
N3_RELEASE=${RELEASE}/next3_snapshot-${DATE}.patch
N3_WIKI=../docs/wiki/Next3_snapshot_patches
LINUX=linux-2.6.31.11
ORIG=origin
BASE=branch
STRIP=./strip_ifdefs
SRC_PREV=head^
SRC_HEAD=head
SRC_HEAD0=head~
PREV=HEAD^
HEAD=HEAD
HEAD0=HEAD~

CFLAGS=-g

INC=${LINUX}/include/linux
INC_FILES=${INC}/jbd.h ${INC}/buffer_head.h ${INC}/journal-head.h ${INC}/magic.h
FS=${LINUX}/fs
FS_FILES=${FS}/Makefile ${FS}/Kconfig ${FS}/buffer.c
N3=${LINUX}/fs/next3
MOD_FILES=${N3}/Kconfig ${N3}/Makefile \
	  ${N3}/balloc.c ${N3}/file.c ${N3}/ialloc.c ${N3}/inode.c ${N3}/ioctl.c \
	  ${N3}/namei.c ${N3}/next3_jbd.c ${N3}/resize.c ${N3}/super.c ${N3}/xattr.c \
	  ${N3}/next3.h ${N3}/next3_i.h ${N3}/next3_jbd.h ${N3}/next3_sb.h
NEW_FILES=${N3}/snapshot.c ${N3}/snapshot_ctl.c ${N3}/snapshot.h \
	  ${N3}/snapshot_debug.c ${N3}/snapshot_debug.h
OLD_FILES=${N3}/acl.c ${N3}/acl.h ${N3}/bitmap.c ${N3}/dir.c ${N3}/fsync.c \
	  ${N3}/hash.c ${N3}/namei.h ${N3}/symlink.c ${N3}/xattr.h \
	  ${N3}/xattr_security.c ${N3}/xattr_trusted.c ${N3}/xattr_user.c
E3=${LINUX}/fs/ext3
E3_INC_FILES=${INC}/ext3_fs.h ${INC}/ext3_fs_i.h ${INC}/ext3_jbd.h ${INC}/ext3_fs_sb.h

N3_FILES=${INC_FILES} ${FS_FILES} ${MOD_FILES} ${NEW_FILES} ${OLD_FILES}

all: next3 e2fs

clean: clean_next3

distclean: clean_next3 clean_e2fs
	rm -rf ${ORIG} ${BASE}

.PHONY: next3 next3_fs series wiki
next3: ${STRIP} rotate_dirs ${BASE} ${N3_FILES} ${N3_PATCH}~
	@test -z ${ID} || diff -Nuarp ${SRC_PREV} ${SRC_HEAD} > ${N3_SUBPATCH}+ || test 1 = 1
	@test -z ${ID} || (diff -Nuarp ${PREV} ${HEAD} >> ${N3_SUBPATCH} ; \
			((echo -n ${ID} ${N3_SUBPATCH} , ; \
			(diffstat ${N3_SUBPATCH}|tail -n 1)) >> next3_series))
	@test -z ${ID0} || (cp ${N3_SUBPATCH} ${N3_ID0PATCH} ; \
			((echo -n ${ID} ${N3_ID0PATCH} , ; \
			(diffstat ${N3_ID0PATCH}|tail -n 1)) >> next3_series0))
	@diff -Nuarp ${BASE} ${SRC_PREV} > _${N3_PATCH}+ || test 1 = 1
	@(cat ${N3_PATCH}~ ; echo "Signed-off-by: ${SIGNATURE}") > _${N3_PATCH}
	@diff -Nuarp ${BASE} ${PREV} >> _${N3_PATCH} || test 1 = 1
	@test ! -z ${KEY} || (cp _${N3_PATCH}+ ${N3_RELEASE}+ ; cp _${N3_PATCH}+ ${N3_PATCH}+)
	@test _${KEY} != _HEAD || (cp _${N3_PATCH} ${N3_RELEASE} ; cp _${N3_PATCH} ${N3_PATCH})
	@test _${ID} != _00 || (cp _${N3_PATCH} ${N3_SUBPATCH} ; \
				cp _${N3_PATCH} ${N3_ID0PATCH} ; \
				cp ${N3_PATCH}~ ${N3_SUBPATCH}~)
	diffstat _${N3_PATCH}|tail -n 1

${N3_PATCH}~:
	(echo "next3_snapshot.patch adds snapshot support to Next3 (after it was cloned from Ext3)." ; echo ) > $@
	(echo "The next3_snapshot patch aggregates all next3_snapshot_X sub-patches and next3_snapshot_X_Y sub-sub-patches." ; echo ) >> $@

next3_fs: ${BASE}
	diff -Nuarp ${ORIG} ${BASE} > ${N3_BASEPATCH} || cp ${N3_BASEPATCH} ${RELEASE}

series: next3_fs next3
	make KEY=exclude_files
	make KEY=block_goal
	make KEY=HEAD
	rm -f next3_series*
	make ID=92 KEY=cleanup_merge
	make ID=91 KEY=cleanup_shrink
	make ID=90 KEY=cleanup
	make ID=82 KEY=exclude_bitmap
	make ID=81 KEY=exclude_inode
	make ID=80 KEY=exclude
	make ID=73 KEY=race_read
	make ID=72 KEY=race_cow
	make ID=71 KEY=race_bitmap
	make ID=70 KEY=race
	make ID=61 KEY=list_peep
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
	make ID=33 KEY=block_move
	make ID=32 KEY=block_bitmap
	make ID=31 KEY=block_cow
	make ID=30 KEY=block
	make ID=23 KEY=file_store
	make ID=22 KEY=file_perm
	make ID=21 KEY=file_peep
	make ID=20 KEY=file
	make ID=13 KEY=hooks_data
	make ID=12 KEY=hooks_delete
	make ID=11 KEY=hooks_jbd
	make ID=10 KEY=hooks
	make ID0=0 ID=01 KEY=debug
	make ID0=0 ID=00 KEY=base
	sort next3_series | ( while read id patch info ; do echo $$patch ; done ) > series

wiki:
	cat series | ( while read patch ; do cat $$patch~ ; done ) > ${N3_WIKI}
	cp ${N3_WIKI} ${RELEASE}

${BASE}: next3.sed next3_fs.sed next3_ext4.sed
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
	sed -i -f next3.sed ${N3}/*
	# rename ext3_* files
	mv ${N3}/ext3_fs.h ${N3}/next3.h
	mv ${N3}/ext3_fs_i.h ${N3}/next3_i.h
	mv ${N3}/ext3_fs_sb.h ${N3}/next3_sb.h
	mv ${N3}/ext3_jbd.h ${N3}/next3_jbd.h
	mv ${N3}/ext3_jbd.c ${N3}/next3_jbd.c
	sed -i -f next3_fs.sed ${N3}/*
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

next3_ext4.sed:
	echo "s/ext4/next3/g" > $@
	echo "s/EXT4/NEXT3/g" >> $@

next3_fs.sed:
	echo "s/linux\/include\/linux\/next3_fs\.h/next3\.h/g" > $@
	echo "s/linux\/include\/linux\/next3_fs_i\.h/next3_i\.h/g" >> $@
	echo "s/linux\/include\/linux\/next3_fs_sb\.h/next3_sb\.h/g" >> $@
	echo "s/linux\/include\/linux\/next3_jbd\.h/next3_jbd\.h/g" >> $@
	echo "s/_LINUX_NEXT3_FS_H/_LINUX_NEXT3_H/g" >> $@
	echo "s/_LINUX_NEXT3_FS_I/_LINUX_NEXT3_I/g" >> $@
	echo "s/_LINUX_NEXT3_FS_SB/_LINUX_NEXT3_SB/g" >> $@
	echo "s/<linux\/next3_fs\.h>/\"next3\.h\"/g" >> $@
	echo "s/<linux\/next3_fs_i\.h>/\"next3_i\.h\"/g" >> $@
	echo "s/<linux\/next3_fs_sb\.h>/\"next3_sb\.h\"/g" >> $@
	echo "s/<linux\/next3_jbd\.h>/\"next3_jbd\.h\"/g" >> $@

.PHONY: rotate_dirs
rotate_dirs:
	@mkdir -p ${SRC_HEAD}
	@test ! -e ${SRC_HEAD}/${LINUX} || rm -rf ${SRC_HEAD}/${LINUX}
	@test ! -e ${SRC_PREV}/${LINUX} || mv ${SRC_PREV}/${LINUX} ${SRC_HEAD}
	@mkdir -p ${SRC_PREV}/${INC} ${SRC_PREV}/${N3}
	@mkdir -p ${SRC_HEAD}/${INC} ${SRC_HEAD}/${N3}
	@mkdir -p ${HEAD}
	@test ! -e ${HEAD}/${LINUX} || rm -rf ${HEAD}/${LINUX}
	@test ! -e ${PREV}/${LINUX} || mv ${PREV}/${LINUX} ${HEAD}
	@mkdir -p ${PREV}/${INC} ${PREV}/${N3}
	@mkdir -p ${HEAD}/${INC} ${HEAD}/${N3}

${INC}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@

${FS}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@

${N3}/%:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY}
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@

${N3}/Kconfig:
	@test ! -z ${KEY} || cp ${SRC}/$@ ${SRC_PREV}/$@
	@test -z ${KEY} || ((${STRIP} ${SRC_HEAD}/$@ ${SRC_PREV}/$@ ${KEY} > ${N3_SUBPATCH}~) && \
			(cat ${N3_SUBPATCH}~ ; echo "Signed-off-by: ${SIGNATURE}") > ${N3_SUBPATCH})
	@${STRIP} ${SRC_PREV}/$@ ${PREV}/$@

${INC}/magic.h: ${BASE}/${INC}/magic.h
	@cp $< ${SRC_PREV}/$@ ; cp $< ${PREV}/$@

${FS}/Kconfig: ${BASE}/${FS}/Kconfig
	@cp $< ${SRC_PREV}/$@ ; cp $< ${PREV}/$@

${FS}/Makefile: ${BASE}/${FS}/Makefile
	@cp $< ${SRC_PREV}/$@ ; cp $< ${PREV}/$@

clean_next3:
	rm -rf ${STRIP} ${LINUX}* next3* series *.patch*
	rm -rf ${SRC_HEAD} ${SRC_PREV} ${HEAD} ${PREV}

#
# e2fsprogs patch
#
E2FS=e2fsprogs-1.41.9
E2FS_ORIG=${E2FS}.orig
E2FS_PATCH=e2fs_next3.patch
E2FS_RELEASE=${RELEASE}/${E2FS}-next3-${DATE}.patch
E2LIB=${E2FS}/lib
E2LIB_FILES=${E2LIB}/e2p/pf.c ${E2LIB}/e2p/feature.c ${E2LIB}/e2p/ls.c \
	${E2LIB}/ext2fs/res_gdt.c ${E2LIB}/ext2fs/swapfs.c ${E2LIB}/ext2fs/mkjournal.c \
	${E2LIB}/e2p/e2p.h ${E2LIB}/ext2fs/ext2fs.h ${E2LIB}/ext2fs/ext2_fs.h
FSCK=${E2FS}/e2fsck
FSCK_FILES=${FSCK}/problem.c ${FSCK}/unix.c ${FSCK}/super.c ${FSCK}/rehash.c \
	${FSCK}/pass1.c ${FSCK}/pass5.c ${FSCK}/problem.h ${FSCK}/e2fsck.h
MISC_FILES=${E2FS}/misc/dumpe2fs.c ${E2FS}/misc/mke2fs.c ${E2FS}/misc/tune2fs.c ${E2FS}/misc/util.c \
	${E2FS}/misc/lsattr.c ${E2FS}/misc/chattr.c ${E2FS}/resize/main.c ${E2FS}/resize/resize2fs.c \
	${E2FS}/debugfs/set_fields.c 
E2FS_FILES=${E2LIB_FILES} ${FSCK_FILES} ${MISC_FILES} ${E2FS}/version.h 

.PHONY: e2fs e2fs_clean
e2fs: ${E2FS_PATCH}

${E2FS_PATCH}: ${E2FS} ${E2FS_FILES}
	diff -Nuarp ${E2FS_ORIG} ${E2FS} > ${E2FS_PATCH} || cp ${E2FS_PATCH} ${E2FS_RELEASE}

${E2FS}:
	rm -rf ${E2FS} ${E2FS_ORIG}
	tar xkfz ${E2FS_PKG}/${E2FS}.tar.gz ${E2FS_FILES}
	cp -a ${E2FS} ${E2FS_ORIG}

${E2FS}/%: ../${E2FS}/%
	cp $< $@

${E2FS}/debugfs/%: ${SRC}/${E2FS}/debugfs/%
	cp $< $@

${E2FS}/misc/%: ${SRC}/${E2FS}/misc/%
	cp $< $@

${E2FS}/resize/%: ${SRC}/${E2FS}/resize/%
	cp $< $@

${E2LIB}/e2p/%: ${SRC}/${E2LIB}/e2p/%
	cp $< $@

${E2LIB}/ext2fs/%: ${SRC}/${E2LIB}/ext2fs/%
	cp $< $@

${FSCK}/%: ${SRC}/${FSCK}/%
	cp $< $@

clean_e2fs:
	rm -rf ${E2FS} ${E2FS_ORIG} ${E2FS_PATCH}

