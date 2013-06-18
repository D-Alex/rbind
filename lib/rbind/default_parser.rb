
module Rbind
    class DefaultParser < RNamespace
        extend ::Rbind::Logger

        def initialize
            super("root")
            self.root = true
            add_default_types
            @on_type_not_found
        end

        def normalize_flags(line_number,flags)
            flags.map do |flag|
                if flag =~ /(\w*)(.*)/
                    DefaultParser.log.debug "input line #{line_number}: ignoring flag #{$2}" unless $2.empty?
                    $1.to_sym
                else
                    raise "cannot parse flag #{flag.inspect}"
                end
            end
        end

        def normalize_default_value(value)
            val = value.gsub(/(.?)std::vector<(.*)>/,'\1vector_\2')
            if value != val
                normalize_default_value(val)
            else
                val
            end
        end

        def add_data_type_name(name)
            t = RDataType.new(name)
            add_type t
            t
        end

        def add_namespace_name(name)
            ns = RNamespace.new(name)
            add_type ns
            ns
        end

        def add_struct_name(name)
            s = RStruct.new(name)
            add_type s
            s
        end

        def add_class_name(name)
            klass = RClass.new(name)
            add_type klass
            klass
        end

        def on_type_not_found(&block)
            @on_type_not_found = block
        end


        def find_type(owner,type_name)
            t = owner.type(type_name,false)
            return t if t
            
            normalized = type_name.split("_")
            name = normalized.shift
            while !normalized.empty?
                name += "::#{normalized.shift}"
                t = if normalized.empty?
                        owner.type(name,false)
                    else
                        owner.type("#{name}_#{normalized.join("_")}",false)
                    end
                return t if t
            end
            t = @on_type_not_found.call(owner,type_name) if @on_type_not_found
            return t if t

            #search again even if we know the type is not there to create a proper error message
            owner.type(type_name,true)
        end

        def parameter(line_number,string,owner = self)
            flags = string.split(" /")
            array = flags.shift.split(" ")
            type_name = array.shift
            para_name = array.shift
            default = normalize_default_value(array.join(" "))
            type = find_type(owner,type_name)
            flags = normalize_flags(line_number,flags)
            RParameter.new(para_name,type,default,flags)
        rescue RuntimeError => e
            raise "input line #{line_number}: #{e}"
        end

        def attribute(line_number,string,owner=self)
            flags = string.split(" /")
            array = flags.shift.split(" ")
            type_name = array[0]
            name = array[1]
            type = find_type(owner,type_name)
            flags = normalize_flags(line_number,flags)
            RAttribute.new(name,type,flags)
        rescue RuntimeError => e
            raise "input line #{line_number}: #{e}"
        end

        def parse_class(line_number,string)
            lines = string.split("\n")
            a = lines.shift.rstrip.split(" : ")
            name = a[0].split(" ")[1]
            parents = a[1]
            parent_classes = if parents
                                 parents.split(", ").map do |name|
                                     t = type(RBase.normalize(name),false)
                                     # auto add parent class
                                     t ||= add_type(RClass.new(RBase.normalize(name)))
                                 end
                             end
            t = RClass.new(name,*parent_classes)
            t = if t2 = type(t.full_name,false)
                    if !t2.is_a?(RClass) || (!t2.parent_classes.empty? && t2.parent_classes != t.parent_classes)
                        raise "Cannot add class #{t.full_name}. A different type #{t2} is already registered"
                    else
                        t2.parent_classes = t.instance_variable_get(:@parent_classes)
                        t2
                    end
                else
                    add_type(t)
                    t
                end
            line_counter = 1
            lines.each do |line|
                a = attribute(line_counter+line_number,line,t)
                t.add_attribute(a)
                line_counter += 1
            end
            [t,line_counter]
        rescue RuntimeError  => e
            raise "input line #{line_number}: #{e}"
        end

        def parse_struct(line_number,string)
            a = string.split("\n")
            first_line = a.shift
            flags = first_line.split(" /")
            name = flags.shift.split(" ")[1]
            flags = normalize_flags(line_number,flags)
            klass = RStruct.new(name,flags)
            add_type(klass)
            line_counter = 1
            a.each do |line|
                a = attribute(line_counter+line_number,line,klass)
                klass.add_attribute(a)
                line_counter += 1
            end
            [klass,line_counter]
        rescue RuntimeError  => e
            raise "input line #{line_number}: #{e}"
        end

        def parse_const(line_number,string)
            raise "multi line const are not supported: #{string}" if string.split("\n").size > 1
            a = string.split(" ")
            raise "not a constant: #{string}" unless a.shift == "const"
            name = a.shift
            value = a.join(" ")
            c = RConst.new(name,value)
            add_const(c)
            [c,1]
        end

        def parse_operation(line_number,string)
            a = string.split("\n")
            line = a.shift
            flags = line.split(" /")
            line = flags.shift
            elements = line.split(" ")
            name = elements.shift
            return_type_name = elements.shift
            if return_type_name == "()"
                name += return_type_name
                return_type_name = elements.shift
            end
            alias_name = elements.shift
            alias_name = if alias_name
                             raise "#{line_number}: cannot parse #{string}" unless alias_name =~/^=.*/
                             alias_name.gsub("=","")
                         end

            ns = RBase.namespace(name)
            owner = type(ns,true)
            if return_type_name == "explicit"
                flags << return_type_name
                return_type_name = nil
            end
            return_type = if return_type_name && !return_type_name.empty?
                              find_type(owner,return_type_name)
                          end
            line_counter = 1
            args = a.map do |line|
                p = parameter(line_number+line_counter,line,owner)
                line_counter += 1
                p
            end
            op = ::Rbind::ROperation.new(name,return_type,*args)
            op.alias = alias_name if alias_name && !alias_name.empty?
            op.flags = normalize_flags(line_number,flags)
            type(op.namespace,true).add_operation(op)
            [op,line_counter]
        end

        def parse(string)
            a = split(string)
            a.pop #remove number at the end of the file
            line_number = 1
            a.each do |block|
                begin
                first = block.split(" ",2)[0]
                obj,lines = if first == "const"
                                parse_const(line_number,block)
                            elsif first == "class"
                                parse_class(line_number,block)
                            elsif first == "struct"
                                parse_struct(line_number,block)
                            else
                                parse_operation(line_number,block)
                            end
                line_number+=lines
                rescue RuntimeError => e
                    puts "Parsing Error: #{e}"
                    puts "Line #{line_number}:"
                    puts "--------------------------------------------------"
                    puts block
                    puts "--------------------------------------------------"
                    Kernel.raise
                    break
                end
            end
        end

        def split(string)
            array = []
            string.each_line do |line|
                if !line.empty? && line[0] != " "
                    array << line
                else
                    array[array.size-1] = array.last + line
                end
            end
            array
        end
    end
end
