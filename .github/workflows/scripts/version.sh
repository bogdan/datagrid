#!/bin/sh

set -e

VERSION=$(
  ruby -e "Dir.glob(File.join('./*.gemspec')) { |file| puts Gem::Specification.load(file).version.to_s }"
)

if [ -z "$VERSION" ]; then
  echo "Could not extract version from $VERSION_FILE"
  exit 1
fi

echo "$VERSION"
