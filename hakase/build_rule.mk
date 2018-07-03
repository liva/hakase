HOST=$(shell if [ ! -e /etc/hakase_installed ]; then echo "host"; fi)

ifneq ($(HOST),)
# host environment
VAGRANT_ROOT_DIR=$(shell vagrant -h | grep host_dir: | cut -f2)
VM_ID=$(shell cat $(VAGRANT_ROOT_DIR)/.vagrant/machines/default/virtualbox/id)

define run_remote
	@bash -c 'vagrant ssh -c "$(1)"; exit $${PIPESTATUS[0]}'
endef

define make_wrapper
	@echo Running \"make$1\" on the remote build environment.
	@vboxmanage showvminfo $(VM_ID) | grep "State:" | grep running > /dev/null 2>&1 || vagrant reload
	$(call run_remote, root_dir=$(VAGRANT_ROOT_DIR); pwd=$(CURDIR); cd /vagrant\$${pwd#\$${root_dir}}; env MAKEFLAGS=\"$(MAKEFLAGS)\" make$1)
endef

.DEFAULT_GOAL:=default
default:
	$(call make_wrapper,)

%:
	$(call make_wrapper, $@)
else
# guest environment
ifneq ($(PWD),$(CURDIR))
RECURSIVE=true
endif
ROOT_DIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TEST_DIR=$(ROOT_DIR)tests/
MODULE_DIR = $(ROOT_DIR)build/

MODULES=callback print memrw simple_loader elf_loader interrupt joshu

CXXFLAGS = -g -O0 -MMD -MP -Wall --std=c++14 -iquote $(ROOT_DIR)

load:
ifeq ($(RECURSIVE),)
	@echo "info: Starting FriendLoader."
	@cd $(ROOT_DIR)FriendLoader; make all && ./run.sh load
endif

unload:
ifeq ($(RECURSIVE),)
	@echo "info: Stopping FriendLoader."
	@cd $(ROOT_DIR)FriendLoader; ./run.sh unload
endif

$(MODULE_DIR):
	mkdir -p $(MODULE_DIR)

endif