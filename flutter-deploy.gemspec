# frozen_string_literal: true

require_relative "lib/version"
require 'fileutils'

Gem::Specification.new do |spec|
  spec.name = "flutter-deploy"
  spec.version = Flutter::Deploy::VERSION
  spec.authors = ["wangfei"]
  spec.email = ["firorwang@sohu-inc.com"]

  spec.summary = "flutter deploy"
  spec.description = "flutter deploy"
  spec.homepage = "http://www.baidu.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["lib/**/*.rb"] + %w[README.md]
  spec.bindir = "bin"
  spec.executables = %w[flutter-cli]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "claide", '>= 1.0.2', '< 2.0'
  spec.add_runtime_dependency "cocoapods", "1.11.3"
  spec.add_runtime_dependency 'colored2', '~> 3.1'
  spec.add_runtime_dependency 'tty-box', '~> 0.7.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
