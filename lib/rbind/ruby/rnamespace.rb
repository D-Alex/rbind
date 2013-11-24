module Rbind
    module Ruby
        class RNamespace< DelegateClass(::Rbind::RNamespace)
            include Hooks
            define_hook :on_type_not_found
            define_hook :on_type_look_up
            define_hook :on_add_type

            def initialize(klass)
                super
            end
        end
    end
end

