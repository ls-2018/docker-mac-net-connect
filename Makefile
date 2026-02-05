PROJECT         := github.com/achernev/docker-mac-net-connect
SETUP_IMAGE     := ccr.ccs.tencentyun.com/ls-2018/docker-mac-net-connect
VERSION         := latest
LD_FLAGS        := -X ${PROJECT}/version.Version=${VERSION} -X ${PROJECT}/version.SetupImage=${SETUP_IMAGE}

# Installation paths
BIN_DIR         := /opt/homebrew/bin
LOG_DIR         := /opt/homebrew/var/log/docker-mac-net-connect
PLIST_DIR       := /Library/LaunchDaemons
PLIST_FILE      := ${PLIST_DIR}/docker-mac-net-connect.plist

run:: build-docker run-go
build:: build-docker build-go
install:: build-go
	@echo "Creating installation directories..."
	@sudo mkdir -p ${LOG_DIR}
	@sudo mkdir -p ${PLIST_DIR}
	
	@echo "Installing binary..."
	@sudo mv docker-mac-net-connect ${BIN_DIR}/
	@sudo chmod +x ${BIN_DIR}/docker-mac-net-connect
	
	@echo "Installing launchd plist..."
	@sudo cp docker-mac-net-connect.plist ${PLIST_FILE}
	@sudo chown root:wheel ${PLIST_FILE}
	@sudo chmod 644 ${PLIST_FILE}
	@sudo ls -al ${PLIST_FILE}


	@echo "Loading and starting service..."
	@sudo launchctl bootstrap system ${PLIST_FILE}
	@sudo launchctl kickstart system/docker-mac-net-connect
	@sudo launchctl print system/docker-mac-net-connect
	@echo "Installation complete!"

uninstall::
	@echo "Stopping and unload service..."
	@sudo launchctl bootout system/docker-mac-net-connect
	@echo "Removing binary..."
	@sudo rm -f ${BIN_DIR}/docker-mac-net-connect
	
	@echo "Removing plist file..."
	@sudo rm -f ${PLIST_FILE}
	
	@echo "Removing installation directories..."
	@sudo rmdir ${LOG_DIR} || true
	@echo "Uninstallation complete!"

run-go::
	sudo go run -ldflags "${LD_FLAGS}" ${PROJECT}

build-go::
	go build -ldflags "-s -w ${LD_FLAGS}" ${PROJECT}

build-docker::
	docker build -t ${SETUP_IMAGE}:${VERSION} ./client

build-push-docker::
	docker buildx build --platform linux/amd64,linux/arm64 --push -t ${SETUP_IMAGE}:${VERSION} ./client

test:
	docker rm docker-mac-net-connect-nginx -f
	docker run --name docker-mac-net-connect-nginx -d ccr.ccs.tencentyun.com/acejilam/ib-0y1tg9wj7e:dba37485fee3d4d76d5d82609cc9bccb-latest
	curl `docker inspect docker-mac-net-connect-nginx|jq '.[0].NetworkSettings.Networks.bridge.IPAddress'|tr -d '"'`
	docker rm docker-mac-net-connect-nginx -f