
module Rbind
    module Ruby
        class RParameter < DelegateClass(::Rbind::RParameter)
            include Base

            class << self
                attr_accessor :default_value_map

                def normalize_default_value(parameter)
                    return unless parameter.default_value
                    val = if parameter.type.basic_type? || parameter.type.ptr?
                              if RParameter.default_value_map.has_key?(parameter.default_value)
                                  RParameter.default_value_map[parameter.default_value]
                              elsif parameter.type.name == "float"
                                  parameter.default_value.gsub("f","")
                              elsif parameter.type.name == "double"
                                  parameter.default_value.gsub(/\.$/,".0").gsub(/^\./,"0.")
                              else
                                  RDataType.normalize_name(parameter.default_value)
                              end
                          else
                              if(parameter.default_value.gsub(/^new /,"") =~ /([ \w:<>]*) *\((.*)\)/)
                                  value = $2
                                  t = parameter.owner.owner.type($1,false)
                                  ops = Array(parameter.owner.owner.operation($1,false)) if !t
                                  t,ops = if t || !ops.empty?
                                              [t,ops]
                                          else
                                              ns = RBase.namespace($1)
                                              name = RBase.basename($1)
                                              if ns && name
                                                  t = parameter.owner.owner.type(ns,false)
                                                  ops = Array(t.operation(name,false)) if t
                                                  [t,ops]
                                              else
                                                  [nil,nil]
                                              end
                                          end
                                  s = if ops && !ops.empty?
                                          if t
                                              "#{t.to_ruby.full_name)}::#{ops.first.to_ruby.name}(#{(value)})"
                                          else
                                              "#{ops.first.to_ruby.name)}(#{(value)})"
                                          end
                                      elsif t
                                          t = t.to_ptr if parameter.type.ptr?
                                          "#{t.to_ruby.full_name)}.new(#{(value)})"
                                      end
                              else
                                  parameter.default_value
                              end
                          end
                    if val
                        val
                    else
                        raise "cannot parse default parameter value #{parameter.default_value} for #{parameter.owner.signature}"
                    end
                end
            end
        end
        self.default_value_map ||= {"true" => "true","TRUE" => "true", "false" => "false","FALSE" => "false"}

        attr_accessor :default_value,:name,:full_name
        def initialize(klass)
            super
        end

        # renders the default value of the parameter as ruby conform string
        def default_value
            if @default_value
                @default_value
            else
                RParameter.normalize_default_value(to_orig)
            end
        end

        # TODO should we automatically fix full_name ?
        def name
            if @name
                @name
            else
                RDataType::normalize_name(to_orig.to_raw.name)
            end
        end

        def full_name
            if @full_name
                @full_name
            else
                if extern_package_name
                    "::#{extern_package_name}::#{RDataType::normalize_name(to_orig.to_raw.full_name)}"
                else
                    RDataType::normalize_name(to_orig.to_raw.full_name)
                end
            end
        end
    end
end

