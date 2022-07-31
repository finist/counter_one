# frozen_string_literal: true

require_relative "lib/counter_one/version"

Gem::Specification.new do |spec|
  spec.name          = "counter_one"
  spec.version       = CounterOne::VERSION
  spec.authors       = ["Nikolay Seskin"]
  spec.email         = ["nseskin@gmail.com"]

  spec.summary       = "Improved counter cache for Rails app."
  spec.description   = "CounterOne provides improved counter cache for Rails app with support various relationships and conditions."
  spec.homepage      = "https://github.com/finist/counter_one"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/finist/counter_one"
  spec.metadata["changelog_uri"] = "https://github.com/finist/counter_one/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>= 4.2'
  spec.add_dependency 'activesupport', '>= 4.2'
  spec.add_development_dependency 'sqlite3'

end
