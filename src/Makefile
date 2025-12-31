STRONGSWAN_IMAGE = nam-infra/strongswan

TAG = latest

.PHONY: build-strongswan
build-strongswan:
	docker build -t $(STRONGSWAN_IMAGE):$(TAG) ./strongswan

.PHONY: build
build: build-strongswan

.PHONY: run
run:
	docker compose up -d

.PHONY: down
down:
	docker compose down

