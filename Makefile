PACKAGE = anopa
ORG = amylum
BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz

PACKAGE_VERSION = $$(awk -F= '/^version/ {print $$2}' upstream/package/info)
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)
CONF_FLAGS = --enable-static --disable-slashpackage --enable-static-libc
PATH_FLAGS = --prefix=$(RELEASE_DIR) --exec-prefix=$(RELEASE_DIR)/usr --libdir=$(RELEASE_DIR)/usr/lib/anopa --dynlibdir=$(RELEASE_DIR)/usr/lib --includedir=$(RELEASE_DIR)/usr/include --libexecdir=$(RELEASE_DIR)/usr/bin --sbindir=$(RELEASE_DIR)/usr/bin --with-include=/tmp/include

SKALIBS_VERSION = 2.3.3.0-24
SKALIBS_URL = https://github.com/amylum/skalibs/releases/download/$(SKALIBS_VERSION)/skalibs.tar.gz
SKALIBS_TAR = skalibs.tar.gz
SKALIBS_DIR = /tmp/skalibs
SKALIBS_PATH = --with-sysdeps=$(SKALIBS_DIR)/usr/lib/skalibs/sysdeps --with-lib=$(SKALIBS_DIR)/usr/lib/skalibs --with-include=$(SKALIBS_DIR)/usr/include --with-dynlib=$(SKALIBS_DIR)/usr/lib

S6_VERSION = 2.1.3.0-24
S6_URL = https://github.com/amylum/s6/releases/download/$(S6_VERSION)/s6.tar.gz
S6_TAR = s6.tar.gz
S6_DIR = /tmp/s6
S6_PATH = --with-lib=$(S6_DIR)/usr/lib/s6 --with-include=$(S6_DIR)/usr/include --with-lib=$(S6_DIR)/usr/lib

EXECLINE_VERSION = 2.1.1.1-16
EXECLINE_URL = https://github.com/amylum/execline/releases/download/$(EXECLINE_VERSION)/execline.tar.gz
EXECLINE_TAR = execline.tar.gz
EXECLINE_DIR = /tmp/execline
EXECLINE_PATH = --with-lib=$(EXECLINE_DIR)/usr/lib/execline --with-include=$(EXECLINE_DIR)/usr/include --with-lib=$(EXECLINE_DIR)/usr/lib

.PHONY : default submodule manual container deps version build push local

default: submodule container

submodule:
	git submodule update --init

manual: submodule
	./meta/launch /bin/bash || true

container:
	./meta/launch

deps:
	rm -rf $(SKALIBS_DIR) $(SKALIBS_TAR) $(S6_DIR) $(S6_TAR) $(EXECLINE_DIR) $(EXECLINE_TAR)
	mkdir $(SKALIBS_DIR) $(S6_DIR) $(EXECLINE_DIR)
	curl -sLo $(SKALIBS_TAR) $(SKALIBS_URL)
	tar -x -C $(SKALIBS_DIR) -f $(SKALIBS_TAR)
	curl -sLo $(S6_TAR) $(S6_URL)
	tar -x -C $(S6_DIR) -f $(S6_TAR)
	curl -sLo $(EXECLINE_TAR) $(EXECLINE_URL)
	tar -x -C $(EXECLINE_DIR) -f $(EXECLINE_TAR)
	rm -rf /tmp/include
	mkdir /tmp/include
	cp -R /usr/include/{linux,asm,asm-generic} /tmp/include

build: submodule deps
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	find $(BUILD_DIR)/src/scripts -type f | xargs sed -i 's|#!.*execlineb|#!/usr/bin/execlineb|'
	cd $(BUILD_DIR) && CC="musl-gcc" ./configure $(CONF_FLAGS) $(PATH_FLAGS) $(SKALIBS_PATH) $(S6_PATH) $(EXECLINE_PATH)
	cd $(BUILD_DIR) && ./tools/gen-deps.sh > package/deps.mak 2>/dev/null
	sed -i 's|/usr/share/man/man1|$$(prefix)/&|' $(BUILD_DIR)/Makefile
	make -C $(BUILD_DIR) POD2MAN=/usr/bin/core_perl/pod2man
	make -C $(BUILD_DIR) install
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp upstream/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)

local: build push

