.PHONY: all test dep build push checkenv deploy kubefile setup migrate

CI_REGISTRY ?= registry.bukalapak.io
IMAGE = $(CI_REGISTRY)/bukalapak/olympus/$(svc)
BASE_IMAGE = $(CI_REGISTRY)/bukalapak/olympus/base

DIRS  = $(shell cd deploy && ls -d */ | grep -v "_output" | grep -v "docker" | grep -v "manifest")
ODIR := deploy/_output

export VERSION            ?= $(shell git show -q --format=%h)
export VAR_SERVICES       ?= $(DIRS:/=)
export VAR_KUBE_NAMESPACE ?= default
export VAR_CONSUL_PREFIX  ?= olympus

all: build push deploy

test:
	bundle exec rspec --format json --out UT-OLYMPUS-report_tms.json --format progress

$(ODIR):
	mkdir -p $(ODIR)

build:
	@$(foreach svc, $(VAR_SERVICES), \
		docker build --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg BASE_VERSION=$(BASE_VERSION) --build-arg CI_TOKEN="$(CI_JOB_TOKEN)" --build-arg VERSION=${VERSION} -t $(IMAGE):$(VERSION) -f ./deploy/$(svc)/Dockerfile .;)

push:
	@$(foreach svc, $(VAR_SERVICES), \
		docker push $(IMAGE):$(VERSION);)

checkenv:
ifndef ENV
	$(error ENV must be set.)
endif

deploy: checkenv $(ODIR)
	@$(foreach svc, $(VAR_SERVICES), \
		echo deploying "$(svc)" to environment "$(ENV)" && \
		! kubelize genfile --overwrite -c ./ -s $(svc) -e $(ENV) deploy/$(svc)/deployment.yml $(ODIR)/$(svc)/ || \
		kubectl apply -f $(ODIR)/$(svc)/deployment.yml ;)

# only generate files from services
kubefile: checkenv $(ODIR)
	$(foreach svc, $(VAR_SERVICES), \
		$(foreach f, $(shell ls deploy/$(svc)/*.yml), \
			kubelize genfile --overwrite -c ./ -s $(svc) -e $(ENV) $(f) $(ODIR)/$(svc)/;))

setup:
	docker run --rm -it --network host -v $PWD/db:/app/db -v $PWD/.env:/app/.env $(CI_REGISTRY)/sre/migration:0.0.1 db:create
	docker run --rm -it --network host -v $PWD/db:/app/db -v $PWD/.env:/app/.env $(CI_REGISTRY)/sre/migration:0.0.1 db:migrate

migrate:
	docker run --rm -it --network host -v $PWD/db:/app/db -v $PWD/.env:/app/.env $(CI_REGISTRY)/sre/migration:0.0.1 db:migrate

replace-gitlab-url:
	git config --global url."https://gitlab-ci-token:$(CI_JOB_TOKEN)@runner.gitlab.cloud.bukalapak.io/".insteadOf "git@git.gitlab.cloud.bukalapak.io:"
