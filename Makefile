elm: runtime-dependencies
	which elm-live || npm install -g elm-live@^3.4.1
	which concurrently || npm install -g concurrently
	concurrently "make elm-live-create" "make elm-live-view"

elm-live-create:
	elm-live src/Create.elm \
	--dir=public \
	--start-page=create.html \
	-- --output public/client.js

elm-live-view:
	elm-live src/View.elm --no-server \
	--dir=public \
	--start-page=view.html \
	-- --output public/view.js

runtime-dependencies: node_modules build-graphql

node_modules: package.json
	npm install

build-graphql:
	rm -f src/db/*.elm
	node scripts/run-graphql-to-elm.js

clean-graphql:
	rm -rf src/GraphQL src/db/*.elm build/db
