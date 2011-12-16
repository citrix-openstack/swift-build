USE_BRANDING := yes
IMPORT_BRANDING := yes
ifdef B_BASE
include $(B_BASE)/common.mk
include $(B_BASE)/rpmbuild.mk
else
COMPONENT := swift
include ../../mk/easy-config.mk
endif

REPO := $(call hg_loc,$(COMPONENT))
VPX_REPO := $(call hg_loc,os-vpx)


LP_SWIFT_BRANCH ?= lp:swift


SWIFT_UPSTREAM := $(shell test -d /repos/swift && \
			  readlink -f /repos/swift || \
			  readlink -f $(REPO)/upstream)


SWIFT_VERSION := $(shell sed -ne "s,^_version = Version('\(.*\)'.*).*$$,\1,p" \
				 $(SWIFT_UPSTREAM)/swift/__init__.py)
SWIFT_FULLNAME := openstack-swift-$(SWIFT_VERSION)-$(BUILD_NUMBER)
SWIFT_SPEC := $(MY_OBJ_DIR)/openstack-swift.spec
SWIFT_RPM_TMP_DIR := $(MY_OBJ_DIR)/RPM_BUILD_DIRECTORY/tmp/openstack-swift
SWIFT_RPM_TMP := $(MY_OBJ_DIR)/RPMS/noarch/$(SWIFT_FULLNAME).noarch.rpm
SWIFT_TARBALL := $(MY_OBJ_DIR)/SOURCES/$(SWIFT_FULLNAME).tar.gz
SWIFT_RPM := $(MY_OUTPUT_DIR)/RPMS/noarch/$(SWIFT_FULLNAME).noarch.rpm
SWIFT_SRPM := $(MY_OUTPUT_DIR)/SRPMS/$(SWIFT_FULLNAME).src.rpm

EPEL_RPM_DIR := $(CARBON_DISTFILES)/epel5
EPEL_YUM_DIR := $(MY_OBJ_DIR)/epel5

EPEL_REPOMD_XML := $(EPEL_YUM_DIR)/repodata/repomd.xml
REPOMD_XML := $(MY_OUTPUT_DIR)/repodata/repomd.xml

DEB_SWIFT_VERSION := $(shell head -1 $(REPO)/upstream/debian/changelog | \
                          sed -ne 's,^.*(\(.*\)).*$$,\1,p')
SWIFT_DEB := $(MY_OUTPUT_DIR)/swift_$(DEB_SWIFT_VERSION)_all.deb
SWIFT_ACCOUNT_DEB := $(MY_OUTPUT_DIR)/swift-account_$(DEB_SWIFT_VERSION)_all.deb
SWIFT_CONTAINER_DEB := $(MY_OUTPUT_DIR)/swift-container_$(DEB_SWIFT_VERSION)_all.deb
SWIFT_DOC_DEB := $(MY_OUTPUT_DIR)/swift-doc_$(DEB_SWIFT_VERSION)_all.deb
SWIFT_OBJECT_DEB := $(MY_OUTPUT_DIR)/swift-object_$(DEB_SWIFT_VERSION)_all.deb
SWIFT_PROXY_DEB := $(MY_OUTPUT_DIR)/swift-proxy_$(DEB_SWIFT_VERSION)_all.deb
PYTHON_SWIFT_DEB := $(MY_OUTPUT_DIR)/python-swift_$(DEB_SWIFT_VERSION)_all.deb

DEBS := $(SWIFT_DEB) $(SWIFT_ACCOUNT_DEB) $(SWIFT_CONTAINER_DEB) \
	$(SWIFT_DOC_DEB)  $(SWIFT_OBJECT_DEB) $(SWIFT_PROXY_DEB) \
	$(PYTHON_SWIFT_DEB)
RPMS := $(SWIFT_RPM) $(SWIFT_SRPM)

OUTPUT := $(RPMS) $(REPOMD_XML)

.PHONY: build
build: $(OUTPUT)

.PHONY: debs
debs: $(DEBS)

$(SWIFT_ACCOUNT_DEB): $(SWIFT_DEB)
$(SWIFT_CONTAINER_DEB): $(SWIFT_DEB)
$(SWIFT_DOC_DEB): $(SWIFT_DEB)
$(SWIFT_OBJECT_DEB): $(SWIFT_DEB)
$(SWIFT_PROXY_DEB): $(SWIFT_DEB)
$(PYTHON_SWIFT_DEB): $(SWIFT_DEB)
$(SWIFT_DEB): $(shell find $(REPO)/upstream -type f)
	@if ls $(REPO)/*.deb >/dev/null 2>&1; \
	then \
	  echo "Refusing to run with .debs in $(REPO)." >&2; \
	  exit 1; \
	fi
	cd $(REPO)/upstream; \
	  DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -d -b
	mv $(REPO)/*.deb $(@D)
	rm $(REPO)/*.changes
	# The log files end up newer than the .debs, so we never reach a
	# fixed point given this rule's dependency unless we remove them.
	rm $(REPO)/upstream/debian/*.debhelper.log

$(SWIFT_SRPM): $(SWIFT_RPM)
$(SWIFT_RPM): $(SWIFT_SPEC) $(SWIFT_TARBALL) $(EPEL_REPOMD_XML) \
	      $(shell find $(REPO)/openstack-swift -type f) \
	      $(REPO)/build-swift.sh
	cp -f $(REPO)/openstack-swift/* $(MY_OBJ_DIR)/SOURCES
	sh $(REPO)/build-swift.sh $@ $< $(MY_OBJ_DIR)/SOURCES

$(MY_OBJ_DIR)/%.spec: $(REPO)/openstack-swift/%.spec.in
	mkdir -p $(dir $@)
	$(call brand,$^) >$@
	sed -e 's,@SWIFT_VERSION@,$(SWIFT_VERSION),g' -i $@

$(SWIFT_TARBALL): $(shell find $(SWIFT_UPSTREAM) -type f)
	rm -rf $@ $(MY_OBJ_DIR)/openstack-swift-$(SWIFT_VERSION)
	mkdir -p $(@D)
	cp -a $(SWIFT_UPSTREAM) $(MY_OBJ_DIR)/openstack-swift-$(SWIFT_VERSION)
	tar -C $(MY_OBJ_DIR) -czf $@ openstack-swift-$(SWIFT_VERSION)

$(REPOMD_XML): $(RPMS)
	createrepo $(MY_OUTPUT_DIR)

$(EPEL_REPOMD_XML): $(wildcard $(EPEL_RPM_DIR)/%)
	$(call mkdir_clean,$(EPEL_YUM_DIR))
	cp -s $(EPEL_RPM_DIR)/* $(EPEL_YUM_DIR)
	createrepo $(EPEL_YUM_DIR)

.PHONY: rebase
rebase:
	@sh $(VPX_REPO)/rebase.sh $(LP_SWIFT_BRANCH) $(REPO)/upstream

.PHONY: clean
clean:
	rm -f $(OUTPUT)
	rm -rf $(MY_OBJ_DIR)/*
