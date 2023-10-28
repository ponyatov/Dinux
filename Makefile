# var
MODULE = $(notdir $(CURDIR))

# cross
APP        ?= player
HW          = qemu386
include  all/all.mk
include   hw/$(HW).mk
include  cpu/$(CPU).mk
include arch/$(ARCH).mk
include  app/$(APP).mk

# dir
CWD = $(CURDIR)
BIN = $(CWD)/bin
REF = $(CWD)/ref
SRC = $(CWD)/src
TMP = $(CWD)/tmp

# tool
DUB = dub
DC  = dmd
# dmd ldc2 gdc-8 gdc-12
DC  = ldc2
RUN = run   --compiler=$(DC) -v
BLD = build --compiler=$(DC) -v

# src
D += $(wildcard */src/*.d)
J += $(wildcard */src/dub.json) dub.json ldc2.conf

# all
.PHONY: hello
hello: $(wildcard hello/src/*.d) hello/dub.json dub.json ldc2.conf
	$(DUB) $(RUN) :$@

# format
.PHONY: format
format: tmp/format_d
tmp/format_d: $(D)
	$(DUB) $(RUN) dfmt -- -i $? && touch $@

# doc
.PHONY: doc
doc:
	rsync -r ~/metadoc/Dinux doc/
# rsync -r ~/metadoc/cross doc/
# rsync -r ~/metadoc/Linux doc/
# rsync -r ~/metadoc/D     doc/
