module Rbind
    module Ruby
        class RClass < DelegateClass(::Rbind::RClass)

            def initialize(klass)
                super
            end
        end
    end
end
