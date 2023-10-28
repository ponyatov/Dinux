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
RUN = run --compiler=dmd

# src
D += $(wildcard */src/*.d)

# format
.PHONY: format
format: tmp/format_d
tmp/format_d: $(D)
	$(DUB) $(RUN) dfmt -- -i $? && touch $@
