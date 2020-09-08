run-dev:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up elm
.PHONY: run-dev

elm: runtime-dependencies
	which elm-live || npm install -g elm-live@^3.4.1
	which concurrently || npm install -g concurrently
	make elm-live-create
.PHONY: elm

elm-live-create:
	elm-live src/Create.elm \
	--dir=public \
	--start-page=create.html \
	-- --output public/client.js
.PHONY: elm-live-create

elm-live-view:
	elm-live src/View.elm --no-server \
	--dir=public \
	--start-page=view.html \
	-- --output public/view.js
.PHONY: elm-live-view

infra-dependencies:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up graphql-engine graphql-console

runtime-dependencies: node_modules build-graphql
.PHONY: runtime-dependencies

node_modules: package.json
	npm install
.PHONY: node_modules

build-graphql:
	rm -f src/db/*.elm
	node scripts/run-graphql-to-elm.js
.PHONY: build-graphql

clean-graphql:
	rm -rf src/GraphQL src/db/*.elm build/db
.PHONY: clean-graphql
