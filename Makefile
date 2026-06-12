# linux_study — Makefile
#
#   make               build the binary
#   make run           build and serve on :8080
#   make linux-image   build the Docker study container image
#   make linux-shell   drop into the study container interactively
#   make clean         remove binary and SQLite DB

BINARY    := linux_study
ADDR      ?= :8080
DB        ?= linux_study.db
ROOT      ?= .
IMAGE     := linux-study:latest

.DEFAULT_GOAL := build

.PHONY: help
help:
	@awk 'BEGIN{FS=":.*##"} /^## / {sub(/^## /,""); split($$0,a,":"); printf "  \033[36m%-18s\033[0m %s\n", a[1], a[2]}' $(MAKEFILE_LIST)

## build: compile the server binary
.PHONY: build
build:
	go build -o $(BINARY) .

## run: build and start the server (auto-migrates, auto-builds Docker image)
.PHONY: run
run: build
	./$(BINARY) serve --addr $(ADDR) --db $(DB) --root $(ROOT)

## serve: run without rebuilding
.PHONY: serve
serve:
	go run . serve --addr $(ADDR) --db $(DB) --root $(ROOT)

## linux-image: build the Docker container image for terminal exercises
.PHONY: linux-image
linux-image:
	docker build -f Dockerfile.linux -t $(IMAGE) .
	@echo "Built $(IMAGE)"

## linux-shell: open an interactive shell in the study container
.PHONY: linux-shell
linux-shell:
	docker run --rm -it --name linux-study-debug $(IMAGE) /bin/bash

## test: run unit tests
.PHONY: test
test:
	go test ./internal/...

## vet: run go vet
.PHONY: vet
vet:
	go vet . ./internal/...

## tidy: tidy go.mod/go.sum
.PHONY: tidy
tidy:
	go mod tidy

## clean: remove binary and database
.PHONY: clean
clean:
	rm -f $(BINARY) $(DB) $(DB)-wal $(DB)-shm
