Gem::Specification.new do |spec|
  spec.name = "early_active_model_loader"
  spec.version = "0.1.0"
  spec.authors = ["Rails early-load guard reproducer"]
  spec.summary = "Loads Active Model while Bundler requires Gemfile dependencies"

  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*.rb"] }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel"
end
