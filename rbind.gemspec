Gem::Specification.new do |s|
    s.name              = 'rbind'
    s.version           = '0.0.3'
    s.date              = '2013-06-20'
    s.platform          = Gem::Platform::RUBY
    s.authors           = ['Alexander Duda']
    s.email             = ['Alexander.Duda@dfki.de']
    s.homepage          = 'http://github.com/'
    s.summary           = 'Library for genereating automated ffi-bindings for c/c++ libraries'
    s.description       = ''
    s.files             = `git ls-files`.split("\n")
    s.require_path      = 'lib'
    s.required_rubygems_version = ">= 1.3.6"

    #s.rubyforge_project = s.name
    #s.add_runtime_dependency "other", "~> 1.2"
end
