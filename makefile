CC := clang
LDFLAGS := -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer
# Note: Disabled -Wincompatible-pointer-types-discards-qualifiers
CFLAGS := -std=c2x -g3 -march=native -Wall -Wextra -Wpedantic -Wconversion -Wno-incompatible-pointer-types-discards-qualifiers $(LDFLAGS) -ffunction-sections -fdata-sections
SRCEXT := c

SRCDIR := src
LIBDIR := lib
BUILDDIR := build
BINDIR := bin

# I use this variable to filter out the entrypoint of the "runtime" executable
# when compiling for the "test" executable
ENTRYPOINTOBJ := main.o
TARGET := $(BINDIR)/cipher

TESTDIR := test
TESTTARGET := $(BINDIR)/run-tests

INC := -I include

SOURCES := $(wildcard $(SRCDIR)/*.$(SRCEXT))
OBJECTS := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.o))

TESTSOURCES := $(wildcard $(TESTDIR)/*.$(SRCEXT))
TESTOBJECTS := $(patsubst $(TESTDIR)/%,$(BUILDDIR)/%,$(TESTSOURCES:.$(SRCEXT)=.o))


.PHONY: clean test check-cppcheck check-infer


$(TARGET): $(OBJECTS)
	@echo "Linking..."
	@mkdir -p $(BINDIR)
	$(CC) $(LDFLAGS) $^ -o $(TARGET)

# main.o contains the entrypoint of the non-test code, filter it out so there aren't two entrypoints
test: $(TESTOBJECTS) $(filter-out $(BUILDDIR)/$(ENTRYPOINTOBJ),$(OBJECTS))
	@echo "Linking test object files...";
	@mkdir -p $(BINDIR)
	$(CC) $(LDFLAGS) $^ -o $(TESTTARGET)
	$(TESTTARGET)

$(BUILDDIR)/%.o: $(SRCDIR)/%.$(SRCEXT)
	@echo "Building object files...";
	@mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

$(BUILDDIR)/%.o: $(TESTDIR)/%.$(SRCEXT)
	@echo "Building test object files...";
	@mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<


clean:
	@echo "Cleaning...";
	$(RM) -r $(BUILDDIR)/*.o $(TARGET) $(TESTTARGET)


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
		-- make
	$(MAKE) clean
