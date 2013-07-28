
module Rbind
    class RTemplateParameter < RDataType
        def initialize(name,*flags)
            super
        end

        def template?
            true
        end
    end
end
