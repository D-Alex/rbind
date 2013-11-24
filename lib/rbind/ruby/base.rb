module Rbind
    module Ruby
        module Base
            def initialize(klass)

            end

            def to_orig
                __get_obj__
            end
        end
    end
end
