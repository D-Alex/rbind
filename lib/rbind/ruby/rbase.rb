module Rbind
    class RBase
        # returns a proxy object giving the ruby view onto the c++ object
        #
        # @return [Ruby::RBase]
        def to_ruby
            @view_ruby ||= Ruby::RBase.new(self)
        end
    end

    module Ruby
        class RBase < DelegateClass(::Rbind::RBase)
            attr_accessor :name
            attr_accessor :owner
            attr_accessor :version
            attr_accessor :signature
            attr_accessor :doc

            # Creates a new proxy class for getting a ruby view onto the RBase object
            #
            # @param klass [RBase] the RBase object
            def initialize(klass)
                super
            end
        end
    end
end
