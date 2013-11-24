
module Rbind
    module Ruby
        class ROperation < DelegateClass(::Rbind::ROperation)
            class << self

                def normalize_alias_name(orig_name)
                    name = orig_name

                    #replace operatorX with the correct ruby operator when 
                    #there are overloaded operators
                    name = if name =~/^operator(.*)/
                               n = $1
                        if n =~ /\(\)/
                            raise "forbbiden method name #{name}"
                        elsif not n=~ /([\w\d]|[^\W\D])/
                            # consider number suffix for operations
                            # TODO: why actually does that need consideration?
                            n =~ /(.*)(\d)?/
                            # non word and not digit, but also not word
                            # nor digit ->> special characters appended
                            if n == "=="
                                # that one can stay also in ruby
                                n
                            else
                                alias_name = RNamespace.default_operator_alias[$1]
                                if not alias_name
                                    raise ArgumentError, "Normalization failed. Operator: #{$1} unknown"
                                end
                                "#{alias_name}_operator#{$2}"
                            end
                        else
                            if n == "++"
                                "plusplus_operator#{$2}"
                            elsif n == "--"
                                "minusminus_operator#{$2}"
                            else
                                n
                            end
                        end
                           else
                               name
                           end
                end

                # normalize c method to meet ruby conventions
                # see unit tests
                def normalize_name(orig_name)
                    #remove cprefix and replaced _X with #X
                    name = orig_name.to_s.gsub(/\A#{RBase.cprefix}/, "") .gsub(/_((?<!\A)\p{Lu})/u, '#\1')
                    #replaced X with _x
                    name = name.gsub(/(?<!\A)[\p{Lu}\d]/u, '_\0').downcase
                    #replaced _x_ with #x#
                    name = name.to_s.gsub(/[_#]([a-zA-Z\d])[_#]/u, '#\1#')
                    #replaced _x$ with #x
                    name = name.to_s.gsub(/[_#]([a-zA-Z\d])$/u, '#\1')
                    #replaced ## with _
                    name = name.gsub(/##/, '_')
                        #replace #xx with _xx
                        name = name.gsub(/#([a-zA-Z\d]{2})/, '_\1')
                        #remove all remaining #
                        name = name.gsub(/#/, '')
                        name = normalize_alias_method_name(name)
                    raise RuntimeError, "Normalization failed: generated empty name for #{orig_name}" if name.empty?
                    name
                end
            end

            attr_accessor :name
            def initialize()
                super
            end

            def name
                if @name
                    @name
                else
                    ROperation.normalize_name(to_orig.cname)
                end
            end

            def render_ffi
                args = to_orig.cparameters.map do |p|
                    p.type.to_ruby.to_ffi
                end
                "attach_function :#{name},:#{cname},[#{args.join(",")}],#{return_type}\n"
            end

            def return_type
                op = to_orig
                if op.constructor?
                    op.owner.to_ruby.to_ffi
                else
                    op.return_type.to_ruby.to_ffi
                end
            end

            def to_orig
                __get_obj__
            end
        end
    end
end
