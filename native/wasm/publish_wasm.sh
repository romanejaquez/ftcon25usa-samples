#!/bin/bash

set -ex

# Build the wasm and js files that will be released.
pushd ../
./build.sh clean wasm release single-threaded flutter-runtime
./build.sh clean wasm release compatibility flutter-runtime
popd

# Bump version in package.json and referenced by dart code. This very
# intentionally bumps major version.
npm run bump-version

# Publish to npm
npm publish --access public
