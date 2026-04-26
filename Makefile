.PHONY: all build cmake format flash-st flash-jlink clean

PROJECT_NAME ?= firmware
BUILD_DIR    ?= build
BUILD_TYPE   ?= debug
FIRMWARE     := $(BUILD_DIR)/$(PROJECT_NAME).bin
DEVICE       ?= STM32F407VG

all: build

build: cmake
	$(MAKE) -C $(BUILD_DIR) --no-print-directory

cmake: $(BUILD_DIR)/Makefile

$(BUILD_DIR)/Makefile: CMakeLists.txt
	cmake \
		-G "Unix Makefiles" \
		-B$(BUILD_DIR) \
		-DPROJECT_NAME=$(PROJECT_NAME) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DDUMP_ASM=OFF

SRCS := $(shell find Project -name '*.[ch]' -or -name '*.[ch]pp') Core/Src/main.c
format: $(addsuffix .format,$(SRCS))
%.format: %
	clang-format -i $

flash-st: build
	st-flash --reset write $(FIRMWARE) 0x08000000

$(BUILD_DIR)/jlink-script:
	touch $@
	@echo device $(DEVICE) > $@
	@echo si 1 >> $@
	@echo speed 4000 >> $@
	@echo loadfile $(FIRMWARE),0x08000000 >> $@
	@echo -e "r\ng\nqc" >> $@

flash-jlink: build | $(BUILD_DIR)/jlink-script
	JLinkExe -commanderScript $(BUILD_DIR)/jlink-script

clean:
	rm -rf $(BUILD_DIR)
