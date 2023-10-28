# var
MODULE = $(notdir $(CURDIR))

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
RUN = run   --compiler=$(DC)
BLD = build --compiler=$(DC)

# src
D += $(wildcard */src/*.d)
J += $(wildcard */src/dub.json) dub.json

# all
.PHONY: hello
hello: $(wildcard hello/src/*.d) hello/dub.json dub.json
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
