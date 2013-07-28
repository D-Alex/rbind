
module Rbind
    class RTemplateClass < RClass

        def initialize(name,*parent_classes)
            raise "parent classes for template classes are not supported!" if !parent_classes.empty?
            super
        end

        def template?
            true
        end

        def specialize(name,*parameter)
            klass = RClass.new(name)
        end
    end
end
