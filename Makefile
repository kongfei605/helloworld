.SILENT :
.PHONY : main clean dist
GOPATH := ${PWD}:${GOPATH}
export GOPATH
DATE := `date '+%Y%m%d'`
WITH_ENV = env `cat .env 2>/dev/null | xargs`

NAME:= xxx
ROOF:="$(NAME)"
TAG:=`git describe --tags --always`
LDFLAGS:=-X $(ROOF)/config.Version=$(DATE).$(TAG)

all: main

deps:
	go get github.com/gin-gonic/gin
	go get github.com/gin-gonic/contrib/sentry
	go get gopkg.in/go-pg/sharding.v4
	go get gopkg.in/pg.v4

main: vet 
	echo "Building $(NAME)"
	@$(WITH_ENV) go install -gcflags "-N -l" -ldflags "$(LDFLAGS)" $(NAME)


vet:
	@$(WITH_ENV) go vet $(NAME)

test-models:
	 @$(WITH_ENV)   go test -v  -cover  -coverprofile cover_models.out $(NAME)/models
	 @$(WITH_ENV)	go tool cover -html=cover_models.out -o cover.html

clean:
	rm -f *.tar.xz
	rm -rf dist
	rm -f bin/$(NAME)
	if [ -d pkg ] ; then rm -r pkg ; fi

dist: clean
	mkdir -p dist/linux_amd64 && GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/linux_amd64/bin/$(NAME) $(NAME)
	mkdir -p dist/darwin_amd64 && GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/darwin_amd64/bin/$(NAME) $(NAME)

release: dist
	tar -cvJf $(NAME)-linux-amd64-$(TAG).tar.xz bin conf logs -C dist/linux_amd64 bin
	tar -cvJf $(NAME)-darwin-amd64-$(TAG).tar.xz bin conf logs -C dist/darwin_amd64 bin 
