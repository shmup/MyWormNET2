.PHONY: build run clean zip help

build:
	dub build

run:
	dub run

clean:
	dub clean
	rm -f mywormnet2-*.zip

zip: build
	zip mywormnet2-linux-x64.zip \
		mywormnet2 \
		mywormnet2.ini \
		motd.txt \
		news.html \
		wwwroot/* \
		README.md \
		COPYING
	@echo "Created mywormnet2-linux-x64.zip"

help:
	@echo "make build  - build mywormnet2"
	@echo "make run    - build and run"
	@echo "make clean  - clean build artifacts"
	@echo "make zip    - create distribution zip"
