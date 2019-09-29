REPO=quay.io/coryodaniel/eviction-operator

build:
	docker build . -t eviction-operator:$(shell make version)

release:
	# docker push current version

latest:
	# woot

version:
	@cat mix.exs | grep version | sed -e 's/.*version: "\(.*\)",/\1/'
