.PHONY: build run clean help

build:
	dub build

run:
	dub run

clean:
	dub clean

help:
	@echo "make build  - build mywormnet2"
	@echo "make run    - build and run"
	@echo "make clean  - clean build artifacts"
