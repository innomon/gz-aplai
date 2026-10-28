GOOSE ?= /Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose
SWIFTC ?= swiftc
CC ?= cc
SDK_PATH ?= $(shell xcrun --show-sdk-path)
PWD ?= $(shell pwd)

.PHONY: all dylib build test clean

all: build

dylib: libapple_ai_bridge.dylib

libapple_ai_bridge.dylib: apple_ai_bridge.swift
	$(SWIFTC) -emit-library -o libapple_ai_bridge.dylib apple_ai_bridge.swift -sdk $(SDK_PATH) -Xlinker -install_name -Xlinker @rpath/libapple_ai_bridge.dylib

build: dylib
	$(GOOSE) -o gz-aplai.c src/main.goose --include $(PWD)/apple_ai_bridge.h --standalone -O2
	$(CC) -O2 gz-aplai.c -o gz-aplai -L. -lapple_ai_bridge -Wl,-rpath,@loader_path -Wl,-rpath,@loader_path/.. -lpthread

test: dylib
	$(GOOSE) -o test/test_all.c test/test_all.goose --include $(PWD)/apple_ai_bridge.h --standalone -O2
	$(CC) -O2 test/test_all.c -o test/test_all -L. -lapple_ai_bridge -Wl,-rpath,@loader_path -Wl,-rpath,@loader_path/.. -lpthread
	./test/test_all
	rm -f test/test_all test/test_all.c

clean:
	rm -f libapple_ai_bridge.dylib gz-aplai gz-aplai.c test_runner test_runner.c
