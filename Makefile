run-dev:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up elm
.PHONY: run-dev

elm: runtime-dependencies
	node scripts/replace_with_env_vars.js
	which elm-live || npm install -g elm-live@^3.4.1
	make elm-live-create
.PHONY: elm

elm-live-create:
	elm-live src/Main.elm \
	--dir=public \
	--pushstate \
	--start-page=index.html \
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
	gq ${HASURA_GRAPHQL_ENDPOINT} -H "X-Hasura-Admin-Secret: ${HASURA_ADMIN_SECRET}" --introspect > schema.graphql
	node scripts/run-graphql-to-elm.js
.PHONY: build-graphql

clean-graphql:
	rm -rf src/GraphQL src/db/*.elm build/db
.PHONY: clean-graphql

build-app:
	npm install elm@latest-0.19.1
	make build-graphql
	elm make src/Main.elm --output public/client.js
	elm make src/View.elm --output public/view.js
	node scripts/replace_with_env_vars.js
.PHONY: build-app
