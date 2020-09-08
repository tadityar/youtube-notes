run-dev:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up elm
.PHONY: run-dev

elm: runtime-dependencies
	which elm-live || npm install -g elm-live@^3.4.1
	make elm-live-view
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
	which gq || npm install -g graphqurl
	gq http://graphql-engine:8080/v1/graphql -H "X-Hasura-Admin-Secret: adminsecret" --introspect > schema.graphql
	node scripts/run-graphql-to-elm.js
.PHONY: build-graphql

clean-graphql:
	rm -rf src/GraphQL src/db/*.elm build/db
.PHONY: clean-graphql
