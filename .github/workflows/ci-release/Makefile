# During development run as "make -f .github/workflows/ci-release/Makefile"


.PHONY: all
all:
	$(MAKE) bootstrap
	$(MAKE) configure
	$(MAKE) build
	$(MAKE) test


.PHONY: bootstrap
bootstrap:
	./bootstrap -u http://sagepad.org/spkg/upstream/configure/
	./bootstrap -d


.PHONY: configure
configure:
	./.github/workflows/ci-release/run-configure.sh


.PHONY: build
build:
	@echo 'Running Build target'
	make -j8 start SAGE_SERVER=http://sagepad.org


.PHONY: test
test:
	@echo 'Running Test target'
	./sage -t -p 8 --all --long --random-seed=1 --only-errors --logfile=logs/ptestlong.log
