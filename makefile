UNAME_S := $(shell uname -s)
# This is only required when linking against RapidCheck during property-based
# testing on MacOS
MACOS_VERSION := $(shell if [ "$(UNAME_S)" = "Darwin" ]; then \
        sw_vers -productVersion | cut -d . -f 1,2 | xargs printf '%s'; \
    fi)

CC := clang
CXX := clang++
LDFLAGS := -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer
# Note: Disabled -Wincompatible-pointer-types-discards-qualifiers
CFLAGS := -std=c2x -g3 -march=native -Wall -Wextra -Wpedantic -Wconversion -Wno-incompatible-pointer-types-discards-qualifiers $(LDFLAGS) -ffunction-sections -fdata-sections
# C++ needs to be used for property-based tests using RapidCheck
# C++20 is the latest standard that can be used as RapidCheck uses some
# features that are now deprecated in C++23
CXXFLAGS := -std=c++20 -g3 -march=native -Wall -Wextra -Wpedantic -Wconversion -Wno-incompatible-pointer-types-discards-qualifiers $(LDFLAGS) -ffunction-sections -fdata-sections

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
TEST_LDLIBS := ""
TEST_TARGET := $(BIN_DIR)/run-tests
# Property-based tests
RC_DIR := $(LIB_DIR)/rapidcheck
RC_LIB := $(RC_DIR)/build/librapidcheck.a
PROP_TEST_INC := $(INC) -isystem $(RC_DIR)/include
PROP_TEST_LDFLAGS := $(LDFLAGS) -L $(RC_DIR)/build
ifeq ($(UNAME_S),Darwin)
    PROP_TEST_LDFLAGS += -mmacosx-version-min=$(MACOS_VERSION)
endif
PROP_TEST_LDLIBS := -l rapidcheck
PROP_TEST_TARGET := $(BIN_DIR)/run-prop-tests

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


.PHONY: all unit-test prop-test clean-deps clean check-cppcheck check-infer


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

$(JSON_DB): $(OBJS) $(TEST_OBJS) $(PROP_TEST_OBJS)
	@echo "Creating JSON Compilation Database..."
	@echo '[' > $@
	cat $(^:=.json) >> $@
	# This awk script removes the trailing comma from the last line
	awk '                           \
    NR==1 {                     \
        text=$$0;                \
        next                    \
    }                           \
    {                           \
        text=text ORS $$0        \
    }                           \
    END {                       \
        sub(/,[^,]*$$/,"",text); \
        print text              \
    }' $(JSON_DB) > temp_compile_commands.json && \
    mv temp_compile_commands.json $(JSON_DB)
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
	$(RM) -r $(RC_DIR)/.git/
	$(RM) $(BUILD_DIR)/rapidcheck.tar.gz
	@echo "\nBuilding RapidCheck..."
	mkdir -p $(RC_DIR)/build && \
    cd $(RC_DIR)/build/ && \
    cmake .. && \
    cmake --build . --parallel $(NPROC)

clean-deps:
	@echo "Cleaning external libraries..."
	$(RM) $(BUILD_DIR)/rapidcheck.tar.gz
	$(RM) -r $(RC_DIR)/


clean:
	@echo "Cleaning...";
	$(RM) -r $(BUILD_DIR)/*.o $(BUILD_DIR)/*.json $(TARGET) $(TEST_TARGET) $(PROP_TEST_TARGET)


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
