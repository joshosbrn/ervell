#
# Make -- the OG build tool.
# Add any build tasks here and abstract complex build scripts into `lib` that
# can be run in a Makefile task like `coffee lib/build_script`.
#

BIN = node_modules/.bin
MIN_FILE_SIZE = 1000

# Start the server
s:
	$(BIN)/coffee index.coffee

# Start the server with forever
sf:
	$(BIN)/forever $(BIN)/coffee index.coffee

# Start the server with foreman and Redis
spc:
	REDIS_URL=redis://127.0.0.1:6379 APP_URL=http://localhost:5000 foreman start

# Start server in debug mode & open node inspector
ssd:
	$(BIN)/node-inspector --web-port=7777 & $(BIN)/coffee --nodejs --debug index.coffee

# Run all of the project-level tests, followed by app-level tests
test: assets
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/test -name '*.coffee' -not -path 'test/helpers/*')

# Generate minified assets from the /assets folder and output it to /public.
assets:
	$(foreach file, $(shell find assets -name '*.coffee' | cut -d '.' -f 1), \
		$(BIN)/browserify $(file).coffee -t jadeify -t caching-coffeeify -u config.coffee > public/$(file).js; \
		$(BIN)/uglifyjs public/$(file).js > public/$(file).min.js; \
		gzip -f public/$(file).min.js; \
		mv public/$(file).min.js.gz public/$(file).min.js.cgz; \
	)
	$(BIN)/stylus assets -o public/assets --inline --include public/
	$(foreach file, $(shell find assets -name '*.styl' | cut -d '.' -f 1), \
		$(BIN)/sqwish public/$(file).css -o public/$(file).min.css; \
		gzip -f public/$(file).min.css; \
		mv public/$(file).min.css.gz public/$(file).min.css.cgz; \
	)

verify:
	if [ $(shell wc -c < public/assets/root.min.css.cgz) -gt $(MIN_FILE_SIZE) ] ; then echo ; echo "root CSS exists" ; else echo ; echo "root CSS asset compilation failed" ; exit 1 ; fi
	if [ $(shell wc -c < public/assets/root.min.js.cgz) -gt  $(MIN_FILE_SIZE) ] ; then echo ; echo "root JS exists" ; else echo; echo "root JS asset compilation failed" ; exit 1 ; fi

deploy: assets verify
	ulimit -n 10000
	$(BIN)/bucketassets -d public/assets -b ervell-production
	heroku config:add \
		ASSET_PATH=//d2hp0ptr16qg89.cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ \
		--app=ervell
	git push git@heroku.com:ervell.git $(branch):master

deploy-with-images: assets verify
	ulimit -n 10000
	$(BIN)/bucketassets -d public/assets -b ervell-production
	$(BIN)/bucketassets -d public/images -b ervell-production
	heroku config:add \
		ASSET_PATH=//d2hp0ptr16qg89.cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ \
		--app=ervell
	heroku config:add \
		IMAGE_PATH=//d2hp0ptr16qg89.cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ \
		--app=ervell
	git push git@heroku.com:ervell.git $(branch):master

deploy-staging: assets verify
	ulimit -n 10000
	$(BIN)/bucketassets -d public/assets -b ervell-production
	$(BIN)/bucketassets -d public/images -b ervell-production
	heroku config:add \
		ASSET_PATH=//d2hp0ptr16qg89.cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ \
		--app=ervell-staging
	heroku config:add \
		IMAGE_PATH=//d2hp0ptr16qg89.cloudfront.net/assets/$(shell git rev-parse --short HEAD)/ \
		--app=ervell-staging
	git push git@heroku.com:ervell-staging.git $(branch):master

.PHONY: test assets
