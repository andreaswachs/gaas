.PHONY: build-dev run-dev clean-dev

build-dev:
	docker build -t gaas-dev -f dockerfiles/Dockerfile.dev .

run-dev:
	docker run -it -v $(shell pwd):/app gaas-dev

clean-dev:
	# TODO: perhaps forcing is not the best option, but dealing with
	# containers depending on the image is annoying to start out with
	docker image rm gaas-dev --force