PROJECT         := github.com/achernev/docker-mac-net-connect
SETUP_IMAGE     := ccr.ccs.tencentyun.com/ls-2018/docker-mac-net-connect
VERSION         := latest
LD_FLAGS        := -X ${PROJECT}/version.Version=${VERSION} -X ${PROJECT}/version.SetupImage=${SETUP_IMAGE}

run:: build-docker run-go
build:: build-docker build-go

run-go::
	sudo go run -ldflags "${LD_FLAGS}" ${PROJECT}

build-go::
	go build -ldflags "-s -w ${LD_FLAGS}" ${PROJECT}

build-docker::
	docker build -t ${SETUP_IMAGE}:${VERSION} ./client

build-push-docker::
	docker buildx build --platform linux/amd64,linux/arm64 --push -t ${SETUP_IMAGE}:${VERSION} ./client
