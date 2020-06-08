SRCS=webhook
GOARM ?= 7
GOOS?=linux
ARCH ?= amd64
TARGET ?= $(CURDIR)
GOLANG_VERSION ?= latest
SRC_DIR = $(notdir $(shell pwd))
REGISTRY ?= quay.io/mengzn
export
test:
	./image.sh test test
bin:
	./image.sh bin $(SRCS)

build:
	./image.sh build $(SRC_DIR)

.PHONY: bin bin

