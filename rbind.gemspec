Gem::Specification.new do |s|
    s.name              = 'rbind'
    s.version           = '0.0.26'
    s.date              = '2014-10-11'
    s.platform          = Gem::Platform::RUBY
    s.authors           = ['Alexander Duda']
    s.email             = ['Alexander.Duda@dfki.de']
    s.homepage          = 'http://github.com/D-Alex/rbind'
    s.summary           = 'Library for genereating automated ffi-bindings for c/c++ libraries'
    s.description       = 'Rbind is developed to automatically generate ruby bindings for OpenCV '\
                          'but is not tight to this library.'\
                          'This gem is still under heavy development and the API might change in the future.'
    s.files             = `git ls-files`.split("\n")
    s.require_path      = 'lib'
    s.required_rubygems_version = ">= 1.3.6"
    s.add_runtime_dependency "hooks", ">= 0.3.1"
    s.add_runtime_dependency "ffi", ">= 1.9.0"

    #s.rubyforge_project = s.name
end
