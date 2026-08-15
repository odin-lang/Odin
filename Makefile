SUPPORTED_LLVM_VERSIONS := 22 21 20 19 18 17
MINIMUM_LLVM_VERSION := 17

CXXFLAGS ?=
CPPFLAGS ?=
LDFLAGS ?=

SRC := src/main.cpp src/libtommath.cpp


PGO_DIR := pgo
PGO_OUT := $(PGO_DIR)/merged.profdata
PGO_CC := llvm-profdata

CXXFLAGS += -std=c++14
DISABLED_WARNINGS := -Wno-switch -Wno-macro-redefined -Wno-unused-value
LDFLAGS += -pthread -lm

OS_ARCH := $(shell uname -m)
OS_NAME := $(shell uname -s)
TARGET := odin

IS_GIT_REPO := $(wildcard .git)
HAS_GIT := $(shell command -v git 2>/dev/null)

ifneq ($(strip $(IS_GIT_REPO)),)
ifneq ($(strip $(HAS_GIT)),)
    GIT_NOSIG := -c log.showSignature=false
    GIT_SHA := $(shell git $(GIT_NOSIG) show --pretty='%h' --no-patch --no-notes HEAD)
    GIT_DATE := $(shell git $(GIT_NOSIG) show "--pretty=%cd" "--date=format:%Y-%m" --no-patch --no-notes HEAD)
    CPPFLAGS += -DGIT_SHA=\"$(GIT_SHA)\"
else
    GIT_DATE := $(shell date +"%Y-%m")
endif
else
    GIT_DATE := $(shell date +"%Y-%m")
endif

CPPFLAGS += -DODIN_VERSION_RAW=\"dev-$(GIT_DATE)\"

ifeq ($(origin LLVM_CONFIG), undefined)
	LLVM_CONFIG := $(shell																						\
		if [ -n "$$(command -v brew 2>/dev/null)" ]; then								\
			for V in $(SUPPORTED_LLVM_VERSIONS); do												\
				P="$$(brew --prefix llvm@$$V 2>/dev/null)/bin/llvm-config"; \
				if [ -x "$$P" ]; then echo "$$P"; exit 0; fi;								\
			done;																													\
		fi;																															\
		if [ -n "$$(command -v llvm-config 2>/dev/null)" ]; then				\
			V=$$(llvm-config --version | awk -F. '{print $$1}');					\
			for S in $(SUPPORTED_LLVM_VERSIONS); do												\
				if [ "$$V" = "$$S" ]; then echo "llvm-config"; exit 0; fi;	\
				done;																													\
		fi;																															\
		for V in $(SUPPORTED_LLVM_VERSIONS); do													\
			if [ -n "$$(command -v llvm-config-$$V 2>/dev/null)" ]; then echo "llvm-config-$$V"; exit 0; fi;	\
			if [ -n "$$(command -v llvm-config$$V 2>/dev/null)" ]; then echo "llvm-config$$V"; exit 0; fi;		\
		done;																														\
	)
endif

ifeq ($(strip $(LLVM_CONFIG)),)
	$(error "No supported llvm-config command found. Set LLVM_CONFIG to proceed.")
endif

LLVM_VERSION_MAJOR := $(shell $(LLVM_CONFIG) --version | awk -F. '{print $$1}')
VALID_LLVM := $(filter $(SUPPORTED_LLVM_VERSIONS),$(LLVM_VERSION_MAJOR))

ifeq ($(VALID_LLVM),)
	$(error "Unsupported LLVM version $(LLVM_VERSION_MAJOR): must be one of $(SUPPORTED_LLVM_VERSIONS)")
endif

ifeq ($(origin CXX), default)
	CXX := $(shell \
		if [ -x "$$(command -v clang++ 2>/dev/null)" ]; then echo "clang++";																	\
		elif [ -x "$$($(LLVM_CONFIG) --bindir)/clang++" ]; then echo "$$($(LLVM_CONFIG) --bindir)/clang++";		\
		fi																																																		\
	)
endif

ifeq ($(strip $(CXX)),)
	$(error "No clang++ command found. Set CXX to proceed.")
endif

LLVM_CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags --ldflags)
LLVM_SYSTEM_LIBS := $(shell $(LLVM_CONFIG) --libs core native --system-libs)

ifeq ($(OS_NAME), Darwin)
    DARWIN_SYSROOT := $(shell																									\
			if [ -n "$$(command -v xcrun 2>/dev/null)" ]; then											\
				echo "--sysroot $$(xcrun --sdk macosx --show-sdk-path)"								\
			elif [ -e "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" ]; then \
				echo "--sysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"	\
			else																																		\
				echo "Warning: MacOSX.sdk not found." >&2;														\
			fi
		)

    CXXFLAGS += $(LLVM_CXXFLAGS) $(DARWIN_SYSROOT)
    LDFLAGS += -liconv -ldl -framework System -lLLVM
else ifeq ($(OS_NAME), FreeBSD)
    CXXFLAGS += $(LLVM_CXXFLAGS)
    LDFLAGS += -lstdc++ $(LLVM_SYSTEM_LIBS)
else ifeq ($(OS_NAME), NetBSD)
    CXXFLAGS += $(LLVM_CXXFLAGS)
    LDFLAGS += -lstdc++ $(LLVM_SYSTEM_LIBS)
else ifeq ($(OS_NAME), Linux)
    CXXFLAGS += $(LLVM_CXXFLAGS)
    LLVM_LIBFILES := $(shell $(LLVM_CONFIG) --libfiles)
    LDFLAGS += -lstdc++ -ldl $(LLVM_SYSTEM_LIBS) $(LLVM_LIBFILES) -Wl,-rpath=\$$ORIGIN
else ifeq ($(OS_NAME), OpenBSD)
    CXXFLAGS += -I/usr/local/include $(LLVM_CXXFLAGS)
    LLVM_LIBDIR := $(shell $(LLVM_CONFIG) --libdir)
    LDFLAGS += -lstdc++ -L/usr/local/lib -Wl,-rpath,$(LLVM_LIBDIR) -liconv $(LLVM_SYSTEM_LIBS)
else
    $(error "Platform \"$(OS_NAME)\" unsupported")
endif


default: all

all: debug demo
	@printf "\nDebug compiler built. Note: run \"make release\" or \"make release-native\" if you want a faster, release mode compiler.\n"

debug: EXTRAFLAGS := -g
debug: $(TARGET)

PGO_ARCH_FLAGS := $(if $(filter arm64 aarch64,$(OS_ARCH)),-O3 -mcpu=native,-O3 -march=native)
$(PGO_OUT): $(SRC)
	@mkdir -p $(PGO_DIR)
	$(CXX) $(SRC) $(DISABLED_WARNINGS) $(CPPFLAGS) $(CXXFLAGS) $(PGO_ARCH_FLAGS)  -O3 -fprofile-generate=$(PGO_DIR) $(LDFLAGS) -o $(PGO_DIR)/$(TARGET)-pgo
	ODIN_ROOT=. LLVM_PROFILE_FILE="$(PGO_DIR)/odin-%m.profraw" ./$(PGO_DIR)/$(TARGET)-pgo run examples/demo -vet -strict-style -- Hellope World
	# TODO - make more profiling example for build
	$(PGO_CC) merge -output=$@ $(PGO_DIR)/*.profraw

pgo: $(PGO_OUT)

release: EXTRAFLAGS := -O3
release: $(TARGET)

release-native: EXTRAFLAGS := $(if $(filter arm64 aarch64,$(OS_ARCH)),-O3 -mcpu=native,-O3 -march=native)
release-native: $(TARGET)

nightly: EXTRAFLAGS := -DNIGHTLY -O3
nightly: $(TARGET)


$(TARGET): pgo
$(TARGET): $(SRC)
	$(CXX) $(SRC) -fprofile-use=$(PGO_OUT) $(DISABLED_WARNINGS) $(CPPFLAGS) $(CXXFLAGS) $(EXTRAFLAGS) $(LDFLAGS) -o $@

demo: $(TARGET)
	./$(TARGET) run examples/demo -vet -strict-style -- Hellope World



report: $(TARGET)
	./$(TARGET) report

clean:
	rm -fr $(TARGET)
	rm -fr $(PGO_DIR)

.PHONY: all default debug release release-native nightly demo report clean pgo
