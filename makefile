BUILD ?= debug

CC := clang
CXX := clang++

# Architecture configuration
ARCH ?= native

UNAME_S := $(shell uname -s)
# This is only required when linking against RapidCheck during property-based
# testing on MacOS
MACOS_VERSION := $(shell if [ "$(UNAME_S)" = "Darwin" ]; then \
        sw_vers -productVersion | cut -d . -f 1,2 | xargs printf '%s'; \
    fi)

ifeq ($(UNAME_S),Darwin)
	# Platform-specific linker flags for dead code elimination
	GC_SECTIONS_FLAG := -Wl,-dead_strip
	# Use sed with -i '' for in-place editing on macOS
	SED_INPLACE := sed -i ''
	# macOS doesn't support static linking!
	STATIC_FLAG := 
	PROP_TEST_LDFLAGS := -mmacosx-version-min=$(MACOS_VERSION)
else
	GC_SECTIONS_FLAG := -Wl,--gc-sections
	SED_INPLACE := sed -i
	STATIC_FLAG := -static
	PROP_TEST_LDFLAGS :=
endif

ifeq ($(BUILD),release)
	CFLAGS_BUILD := -O3 -DNDEBUG
	LDFLAGS_BUILD := $(STATIC_FLAG) $(GC_SECTIONS_FLAG)
	BUILD_SUFFIX := 
else
	SANITIZER_FLAGS := -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer
	CFLAGS_BUILD := -O1 -g3 $(SANITIZER_FLAGS)
	LDFLAGS_BUILD := $(STATIC_FLAG) $(SANITIZER_FLAGS) $(GC_SECTIONS_FLAG)
	BUILD_SUFFIX := -debug
endif

LDFLAGS := $(LDFLAGS_BUILD)

# Project directory structure
SRC_DIR := src
LIB_DIR := lib
BUILD_DIR := build
TEST_DIR := test
BIN_DIR := bin

# I use this variable to filter out the entrypoint of the "runtime" executable
# when compiling for the "test" executable
TARGET := $(BIN_DIR)/cipher

SRC_EXT := c

# Source files
SRC := $(wildcard $(SRC_DIR)/*.$(SRC_EXT))
OBJS := $(SRC:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)

INC := -I include


# Test flags
# Unit tests
TEST_INC := $(INC)
TEST_LDFLAGS := $(LDFLAGS)
TEST_LDLIBS := 
TEST_TARGET := $(BIN_DIR)/run-tests
# Property-based tests
RC_DIR := $(LIB_DIR)/rapidcheck
RC_LIB := $(RC_DIR)/build/librapidcheck.a
PROP_TEST_INC := $(INC) -isystem $(RC_DIR)/include
PROP_TEST_LDFLAGS += $(LDFLAGS) -L $(RC_DIR)/build
PROP_TEST_LDLIBS := -l rapidcheck
PROP_TEST_TARGET := $(BIN_DIR)/run-prop-tests

CFLAGS_COMMON := -march=$(ARCH) \
                 -Wall -Wextra -Wpedantic -Wconversion \
                 -Wno-incompatible-pointer-types-discards-qualifiers \
                 -ffunction-sections -fdata-sections \
                 -MMD -MP

CFLAGS := -std=c2x $(CFLAGS_COMMON) $(CFLAGS_BUILD)
# C++ needs to be used for property-based tests using RapidCheck
# C++20 is the latest standard that can be used as RapidCheck uses some
# features that are now deprecated in C++23
CXXFLAGS := -std=c++20 $(CFLAGS_COMMON) $(CFLAGS_BUILD)

# main.o contains the entrypoint of the non-test code, filter it out so there aren't two entrypoints
COMMON_OBJS := $(filter-out $(BUILD_DIR)/main.o,$(OBJS))

# Test files
TEST_SRC := $(wildcard $(TEST_DIR)/*.$(SRC_EXT))
TEST_OBJS := $(TEST_SRC:$(TEST_DIR)/%.c=$(BUILD_DIR)/%.o)

# Property-based test files
PROP_TEST_SRC := $(wildcard $(TEST_DIR)/*.cpp)
PROP_TEST_OBJS := $(PROP_TEST_SRC:$(TEST_DIR)/%.cpp=$(BUILD_DIR)/%.o)

# Determine number of cores
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)

# JSON Compilation Database file
JSON_DB := compile_commands.json
JSON_FRAGMENTS := $(OBJS:.o=.o.json) $(TEST_OBJS:.o=.o.json)


.PHONY: all unit-test prop-test clean-libs clean-comp-db clean check-cppcheck check-infer check-csa help


all: $(TARGET) $(JSON_DB)

$(TARGET): $(OBJS)
	@echo "Linking executable..."
	@mkdir -p $(BIN_DIR)
	$(CC) $(LDFLAGS) $^ -o $(TARGET)

unit-test: $(TEST_TARGET)
	@echo "Running tests:"
	$(TEST_TARGET)

prop-test: $(PROP_TEST_TARGET)
	@echo "Running property-based tests:"
	RC_PARAMS="max_success=10000" $(PROP_TEST_TARGET)

$(TEST_TARGET): $(TEST_OBJS) $(COMMON_OBJS)
	@echo "Linking unit test object files..."
	@mkdir -p $(BIN_DIR)
	$(CC) $(TEST_LDFLAGS) $^ $(TEST_LDLIBS) -o $(TEST_TARGET)

$(PROP_TEST_TARGET): $(PROP_TEST_OBJS) $(COMMON_OBJS)
	@echo "Linking property-based test object files..."
	@mkdir -p $(BIN_DIR)
	$(CXX) $(PROP_TEST_LDFLAGS) $^ $(PROP_TEST_LDLIBS) -o $(PROP_TEST_TARGET)

$(JSON_DB): $(OBJS) $(TEST_OBJS)
	@echo "Creating JSON Compilation Database..."
	@echo '[' > $@
	@cat $(JSON_FRAGMENTS) >> $@
	@$(SED_INPLACE) '$$ s/,$$//' $@
	@echo ']' >> $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.$(SRC_EXT)
	@echo "Building object files..."
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(INC) -MJ $@.json -c -o $@ $<

$(BUILD_DIR)/%.o: $(TEST_DIR)/%.$(SRC_EXT)
	@echo "Building unit test object files..."
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(TEST_INC) -MJ $@.json -c -o $@ $<

$(BUILD_DIR)/%.o: $(TEST_DIR)/%.cpp $(RC_LIB)
	@echo "Building property-based test object files..."
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(PROP_TEST_INC) -MJ $@.json -c -o $@ $<

$(RC_LIB):
	@echo "\nDownloading RapidCheck..."
	@mkdir -p $(BUILD_DIR)
	wget --output-document=$(BUILD_DIR)/rapidcheck.tar.gz \
    https://api.github.com/repos/emil-e/rapidcheck/tarball/master
	@echo "\nUnpacking RapidCheck..."
	@mkdir -p $(RC_DIR)
	tar --gunzip \
    --extract \
    --strip-components=1 \
    --file $(BUILD_DIR)/rapidcheck.tar.gz \
    --directory $(RC_DIR)/
	$(RM) -rf $(RC_DIR)/.git/
	$(RM) $(BUILD_DIR)/rapidcheck.tar.gz
	@echo "\nBuilding RapidCheck..."
	mkdir -p $(RC_DIR)/build && \
    cd $(RC_DIR)/build/ && \
    cmake .. && \
    cmake --build . --parallel $(NPROC)

clean-libs:
	@echo "Cleaning external libraries..."
	$(RM) $(BUILD_DIR)/rapidcheck.tar.gz
	$(RM) -rf $(RC_DIR)/

clean-comp-db:
	@echo "Cleaning JSON Compilation Database..."
	$(RM) -rf $(JSON_DB)

clean:
	@echo "Cleaning...";
	$(RM) -rf $(BUILD_DIR)/*.o $(BUILD_DIR)/*.json $(TARGET) $(TEST_TARGET) $(PROP_TEST_TARGET)

# --suppress=missingIncludeSystem is needed if cppcheck cannot find the standard headers on your system
check-cppcheck:
	cppcheck . --verbose   \
    --showtime=summary \
    -j 4               \
    -I include/        \
    --enable=all       \
    --suppress=missingIncludeSystem

check-infer:
	$(MAKE) clean
	infer run --cost                  \
    --bufferoverrun               \
    --loop-hoisting               \
    --procedures                  \
    --procedures-attributes       \
    --procedures-name             \
    --procedures-summary          \
    --pulse                       \
    --quandary                    \
    --source-files                \
    --topl                        \
    --no-cxx                      \
    --html                        \
    --write-html                  \
    --issues-tests issues.txt     \
    --cost-issues-tests costs.txt \
    -- make $(TARGET)
	$(MAKE) clean

# Note: Z3 solver is required for crosscheck-with-z3
check-csa:
	$(MAKE) clean
	scan-build -analyze-headers                                          \
        -maxloop 30                                                      \
        -analyzer-config mode=deep                                       \
        -analyzer-config exploration_strategy=dfs                        \
        -analyzer-config max-inlinable-size=500                          \
        -analyzer-config max-nodes=750000                                \
        -analyzer-config track-conditions=true                           \
        -analyzer-config track-conditions-debug=true                     \
        -analyzer-config eagerly-assume=false                            \
        -analyzer-config graph-trim-interval=10                          \
        -analyzer-config unroll-loops=true                               \
        -analyzer-config widen-loops=true                                \
        -analyzer-config ipa=dynamic-bifurcate                           \
        -analyzer-config ipa-always-inline-size=3                        \
        -analyzer-config aggressive-binary-operation-simplification=true \
        -analyzer-config crosscheck-with-z3=true                         \
        -analyzer-config exploration-strategy=unexplored_first_queue     \
        -analyzer-config notes-as-events=true                            \
        --force-analyze-debug-code                                       \
        -enable-checker alpha                                            \
        -enable-checker core                                             \
        -enable-checker deadcode                                         \
        -enable-checker nullability                                      \
        -enable-checker optin                                            \
        -enable-checker security                                         \
        -enable-checker unix                                             \
        -enable-checker alpha.clone                                      \
        -enable-checker alpha.core                                       \
        -enable-checker alpha.deadcode                                   \
        -enable-checker alpha.security                                   \
        -enable-checker alpha.unix                                       \
        $(MAKE)

help:
	@echo "Available targets:"
	@echo "    all            Build optimized version executable. For release, provide env var BUILD=release"
	@echo "    test           Build tests"
	@echo "    clean-libs     Remove library files"
	@echo "    clean-comp-db  Remove JSON Compilation Database"
	@echo "    clean          Remove all build artifacts (including binaries)"
	@echo "    check-cppcheck Run static analysis with Cppcheck"
	@echo "    check-infer    Run static analysis with Infer"
	@echo "    check-csa      Run static analysis with Clang Static Analyzer"
	@echo "    help           Show this help message"

-include $(DEPS)
