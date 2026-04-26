.PHONY: all build cmake format format-linux flash-stlink flash-jlink shell clean

PROJECT_NAME ?= firmware
BUILD_DIR ?= build
FIRMWARE := $(BUILD_DIR)/$(PROJECT_NAME).bin
BUILD_TYPE ?= debug
PLATFORM = $(if $(OS),$(OS),$(shell uname -s))

ifeq ($(PLATFORM),Windows_NT)
    BUILD_SYSTEM ?= MinGW Makefiles
else
    ifeq ($(PLATFORM),Linux)
        BUILD_SYSTEM ?= Unix Makefiles
    else
        @echo "Unsuported platform"
        exit 1
    endif
endif

all: build

build: cmake
	$(MAKE) -C $(BUILD_DIR) --no-print-directory

cmake: $(BUILD_DIR)/Makefile

$(BUILD_DIR)/Makefile: CMakeLists.txt
	cmake \
		-G "$(BUILD_SYSTEM)" \
		-B$(BUILD_DIR) \
		-DPROJECT_NAME=$(PROJECT_NAME) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DDUMP_ASM=OFF

# Formats all user modified source files (add ones that are missing)
SRCS := $(shell find Project -name '*.[ch]' -or -name '*.[ch]pp') Core/Src/main.c
format: $(addsuffix .format,$(SRCS))
%.format: %
	clang-format -i $<

# Formats all CubeMX generated sources to unix style - removes \r from line endings
# Add any new directories, like Middlewares and hidden files
HIDDEN_FILES := .mxproject .project .cproject
FOUND_HIDDEN_FILES := $(shell for f in $(HIDDEN_FILES);do if [[ -e $$f ]]; then echo $$f;fi; done)
FORMAT_LINUX := $(shell find Core Drivers -name '*' -type f; find . -name '*.ioc') $(FOUND_HIDDEN_FILES)

format-linux: $(addsuffix .format-linux,$(FORMAT_LINUX))
%.format-linux: %
	$(if $(filter $(PLATFORM),Linux),dos2unix -q $<,)

# Device specific!
DEVICE ?= STM32F407VG

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
