all: build

PREFIX?=10.19.64.205:4443
FLAGS=
ARCH?=amd64
ALL_ARCHITECTURES=amd64 arm arm64 ppc64le s390x
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64,linux/ppc64le,linux/s390x


VERSION?=v1.2.0
GIT_COMMIT:=$(shell git rev-parse --short HEAD)


KUBE_EVENTER_LDFLAGS=-w -X github.com/AliyunContainerService/kube-eventer/version.Version=$(VERSION) -X github.com/AliyunContainerService/kube-eventer/version.GitCommit=$(GIT_COMMIT)

fmt:
	find . -type f -name "*.go" | grep -v "./vendor*" | xargs gofmt -s -w

build: clean
	GOARCH=$(ARCH) CGO_ENABLED=0 go build -ldflags "$(KUBE_EVENTER_LDFLAGS)" -o kube-eventer  github.com/AliyunContainerService/kube-eventer

sanitize:
	hack/check_gofmt.sh
	hack/run_vet.sh

test-unit: clean sanitize build

ifeq ($(ARCH),amd64)
	GOARCH=$(ARCH) go test --test.short -race ./... $(FLAGS)
else
	GOARCH=$(ARCH) go test --test.short ./... $(FLAGS)
endif

test-unit-cov: clean sanitize build
	hack/coverage.sh

docker-container:
	docker build -t $(PREFIX)/kube-eventer/kube-eventer-$(ARCH):v1.2.1 -f deploy/Dockerfile .
	docker push 10.19.64.205:4443/kube-eventer/kube-eventer-amd64:v1.2.1

clean:
	rm -f kube-eventer

.PHONY: all build sanitize test-unit test-unit-cov docker-container clean fmt
