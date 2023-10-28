# var
MODULE  = $(notdir $(CURDIR))
OS      = $(shell uname -s)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# cross
APP        ?= player
HW          = qemu386
include  all/all.mk
include   hw/$(HW).mk
include  cpu/$(CPU).mk
include arch/$(ARCH).mk
include  app/$(APP).mk

# dir
CWD  = $(CURDIR)
BIN  =  $(CWD)/bin
REF  =  $(CWD)/ref
SRC  =  $(CWD)/src
TMP  =  $(CWD)/tmp
GZ   = $(HOME)/gz
HOST =  $(CWD)/host
ROOT =  $(CWD)/root
FW   =  $(CWD)/fw

# version
## LDC_VER   = 1.35.0 debian 12 libc 2.29 since 1.32.1
LDC_VER      = 1.32.0
BINUTILS_VER = 2.41
## GCC_VER   = 13.2.0 debian 10 gdc-8 too old for build
GCC_VER      = 12.3.0
GMP_VER      = 6.2.1
MPFR_VER     = 4.2.1
MPC_VER      = 1.3.1
ISL_VER      = 0.24
LINUX_VER    = 6.5.6
MUSL_VER     = 1.2.4
BUSYBOX_VER  = 1.36.1

# package
LDC         = ldc2-$(LDC_VER)
LDC_HOST    = $(LDC)-linux-x86_64
LDC_GZ      = $(LDC_OS).tar.xz
LDC_SRC     = ldc-$(LDC_VER)-src.tar.gz
##
BINUTILS    = binutils-$(BINUTILS_VER)
GCC         = gcc-$(GCC_VER)
GMP         = gmp-$(GMP_VER)
MPFR        = mpfr-$(MPFR_VER)
MPC         = mpc-$(MPC_VER)
ISL         = isl-$(ISL_VER)
LINUX       = linux-$(LINUX_VER)
MUSL        = musl-$(MUSL_VER)
BUSYBOX     = busybox-$(BUSYBOX_VER)
##
BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz
GMP_GZ      = $(GMP).tar.gz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
ISL_GZ      = $(ISL).tar.bz2
LINUX_GZ    = $(LINUX).tar.xz
MUSL_GZ     = $(MUSL).tar.gz
BUSYBOX_GZ  = $(BUSYBOX).tar.bz2

# tool
CURL = curl -L -o
DUB  = dub
DC   = dmd
# dmd ldc2 gdc-8 gdc-12
RUN  = run   --compiler=$(DC)
BLD  = build --compiler=$(DC)
LDC2 = /opt/$(LDC_HOST)/bin/ldc2
LBR  = /opt/$(LDC_HOST)/bin/ldc-build-runtime
QEMU = qemu-system-$(ARCH)

# cfg
XPATH    = PATH=$(HOST)/bin:$(PATH)
CFG_HOST = configure --prefix=$(HOST)
BZIMAGE  = tmp/$(LINUX)/arch/x86/boot/bzImage
KERNEL   = $(FW)/$(APP)_$(HW).kernel
INITRD   = $(FW)/$(APP)_$(HW).cpio.gz

# src
D += $(wildcard */src/*.d)
J += $(wildcard */src/dub.json) dub.json ldc2.conf

# all
.PHONY: hello
HELLO_SRC = $(wildcard hello/src/*.d) hello/dub.json dub.json ldc2.conf
hello: $(HELLO_SRC)
	$(DUB) $(RUN) :$@
$(ROOT)/bin/hello: $(HELLO_SRC)
	$(DUB) build --compiler=$(LDC2) --arch=$(TARGET) :hello

.PHONY: root
root: $(ROOT)/bin/hello

.PHONY: $(INITRD)
$(INITRD):
	cd $(ROOT) ; find . -print0 | cpio --null --create --format=newc | gzip -9 > $@

.PHONY: fw
fw: $(KERNEL) $(INITRD) $(ROOT)/bin/hello
$(KERNEL): $(BZIMAGE)
	cp $< $@

.PHONY: qemu
qemu: $(KERNEL) $(INITRD)
	xterm -e $(QEMU) $(QEMU_CFG) \
		-kernel $(KERNEL) -initrd $(INITRD) \
		-nographic -append "console=ttyS0,115200 vga=0x318"

# format
format: tmp/format_c tmp/format_d
tmp/format_c: $(C)
	clang-format -style=file -i $? && touch $@
tmp/format_d: $(D)
	$(DUB) $(RUN) dfmt -- -i $? && touch $@

# clean
.PHONY: distclean
distclean:
	rm -rf host root ; git checkout host root
	$(MAKE) clean
.PHONY: clean
clean:
	rm -rf ref       ; git checkout ref

# doc
.PHONY: doc
doc: doc/yazyk_programmirovaniya_d.pdf doc/Programming_in_D.pdf
	rsync -r ~/metadoc/Dinux doc/
# rsync -r ~/metadoc/cross doc/
# rsync -r ~/metadoc/Linux doc/
# rsync -r ~/metadoc/D     doc/

doc/yazyk_programmirovaniya_d.pdf:
	$(CURL) $@ https://www.k0d.cc/storage/books/D/yazyk_programmirovaniya_d.pdf
doc/Programming_in_D.pdf:
	$(CURL) $@ http://ddili.org/ders/d.en/Programming_in_D.pdf

# install
APT_SRC = /etc/apt/sources.list.d
ETC_APT = $(APT_SRC)/d-apt.list $(APT_SRC)/llvm.list
.PHONY: install update doc gz
install: doc gz $(ETC_APT)
	sudo apt update && sudo apt --allow-unauthenticated install -yu d-apt-keyring
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.$(OS)`
$(APT_SRC)/%: tmp/%
	sudo cp $< $@
tmp/d-apt.list:
	$(CURL) $@ http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list

gz: $(LDC2) $(GZ)/$(LDC_SRC) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ)       \
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) $(GZ)/$(ISL_GZ)   \
	$(GZ)/$(LINUX_GZ) $(GZ)/$(MUSL_GZ) $(GZ)/$(BUSYBOX_GZ)

$(LDC2): $(GZ)/$(LDC_GZ)
	cd /opt ; sudo sh -c "xzcat $< | tar x && touch $@"
$(GZ)/$(LDC_GZ):
	$(CURL) $@ https://github.com/ldc-developers/ldc/releases/download/v$(LDC_VER)/$(LDC_GZ)
$(GZ)/$(LDC_SRC):
	$(CURL) $@ https://github.com/ldc-developers/ldc/releases/download/v$(LDC_VER)/$(LDC_SRC)

$(GZ)/$(GMP_GZ):
	$(CURL) $@ https://github.com/alisw/GMP/archive/refs/tags/v$(GMP_VER).tar.gz
$(GZ)/$(MPFR_GZ):
	$(CURL) $@ https://www.mpfr.org/mpfr-current/$(MPFR_GZ)
$(GZ)/$(MPC_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/mpc/$(MPC_GZ)
$(GZ)/$(ISL_GZ):
	$(CURL) $@ https://gcc.gnu.org/pub/gcc/infrastructure/$(ISL_GZ)

$(GZ)/$(BINUTILS_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/binutils/$(BINUTILS_GZ)
$(GZ)/$(GCC_GZ):
	$(CURL) $@ http://mirror.linux-ia64.org/gnu/gcc/releases/$(GCC)/$(GCC_GZ)

$(GZ)/$(LINUX_GZ):
	$(CURL) $@ https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_GZ)
$(GZ)/$(MUSL_GZ):
	$(CURL) $@ https://musl.libc.org/releases/$(MUSL_GZ)
$(GZ)/$(BUSYBOX_GZ):
	$(CURL) $@ https://busybox.net/downloads/$(BUSYBOX_GZ)

# merge

