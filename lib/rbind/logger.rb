require 'logger'

module Rbind
    module Logger
        attr_accessor :log
        def self.extend_object(o)
            super
            o.log = ::Logger.new(STDOUT)
            o.log.level = ::Logger::INFO
            o.log.progname = o.name
        end
    end
    extend ::Rbind::Logger
end
