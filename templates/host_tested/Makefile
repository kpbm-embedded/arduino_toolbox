# @NAME@ host tests: `arduino-box run make test` (pixi g++), or plain `make test` with any C++17 compiler.
CXX ?= c++
HOST_OUT ?= build-host

test: $(HOST_OUT)/test_logic
	$(HOST_OUT)/test_logic

$(HOST_OUT)/test_logic: tests/test_logic.cpp src/logic.cpp src/logic.h
	mkdir -p $(HOST_OUT)
	$(CXX) -std=c++17 -Wall -Wextra -Werror -Isrc tests/test_logic.cpp src/logic.cpp -o $@

.PHONY: test
