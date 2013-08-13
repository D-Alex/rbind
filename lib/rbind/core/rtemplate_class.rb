
module Rbind
    class RTemplateParameter < RDataType
        def template?
            true
        end
    end

    class RTemplateClassSpecialization < RClass
        attr_accessor :template,:template_parameters

        def initialize(name,template,*parameters)
            super(name)
            @name = @name.gsub(">>","> >") # force overwrite to match c++ syntax
            @template = template
            @template_parameteres = parameters
        end

        def specialize_ruby
            template.specialize_ruby_specialization(self)
        end
    end

    class RTemplateClass < RClass
        def initialize(name,*parent_classes)
            raise "parent classes for template classes are not supported!" if !parent_classes.empty?
            super
        end

        def template?
            true
        end

        # called by RNamespace
        def do_specialize(name,*parameters)
            klass = RTemplateClassSpecialization.new(name,self,*parameters)
            specialize(klass,*parameters)
        end

        # hook for implementing the specialization
        def specialize(klass,*parameters)
        end

        # hook for generating additional ruby code going to be embedded into the
        # class definition
        def specialize_ruby_specialization(klass)
        end
    end
end
