include ../../build_rule.mk

ifeq ($(HOST),)

OBJS:=$(addsuffix .o,$(TESTS)) $(TEST_DIR)test.o
DEPS:=$(OBJS:%.o=%.d)
TEST_BINS:=$(addsuffix .bin, $(TESTS))
DEPLOY_FILES:=$(TEST_BINS) $(EX_DEPLOY_FILES)
.DEFAULT_GOAL:=test

-include $(DEPS)

.PHONY: test clean pre-deploy

%.bin: %.o $(TEST_DIR)test.o $(foreach lib, $(LIBRARIES), $(MODULE_DIR)lib$(lib).a)
	g++ $(CXXFLAGS) -o $@ $^

test:
	$(MAKE) -C $(ROOT_DIR) prepare_test
	$(MAKE) pre-deploy
	$(MAKE) -C $(ROOT_DIR) execute_test

clean:
	rm -f *.bin $(OBJS) $(DEPS) $(TMP_FILES)

pre-deploy: $(TEST_BINS) $(DEPLOY_FILES)
	mkdir -p $(DEPLOY_DIR)$(RELATIVE_DIR)/
	$(foreach file, $(DEPLOY_FILES), cp $(file) $(DEPLOY_DIR)$(RELATIVE_DIR)/$(file) &&) :
	$(foreach file, $(TEST_BINS), echo "$(QEMU_DIR)/test_hakase.sh 0 $(QEMU_DIR)$(RELATIVE_DIR)/$(file) $(ARGUMENTS)" >> $(RUN_SCRIPT) &&) :

endif