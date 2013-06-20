
module Rbind
    class RClass < RStruct
        attr_reader :parent_classes

        def initialize(name,*parent_classes)
            @parent_classes  = Hash.new
            parent_classes.flatten!
            parent_classes.each do |p|
                add_parent(p)
            end
            super(name)
        end

        def attributes
            attribs = @attributes.values
            parent_classes.each do |k|
                others = k.attributes
                others.delete_if do |other|
                    attribs.inclue? other
                end
                others = others.map(&:dup)
                others.each do |other|
                    other.owner = self
                end
                attribs += others
            end
            attribs
        end

        def attribute(name)
            attrib = @attributes[name]
            attrib ||= begin
                           p = parent_classes.find do |k|
                               k.attribute(name)
                           end
                           a = p.attribute(name).dup if p
                           a.owner = self if a
                           a
                       end
        end

        def operations
            # temporarily add all base class operations
            own_ops = @operations.dup
            parent_classes.each do |k|
                k.operations.each do |other_ops|
                    next if other_ops.empty?
                    ops = if @operations.has_key?(other_ops.first.name)
                            @operations[other_ops.first.name]
                          else
                              []
                          end
                    other_ops.delete_if do |other_op|
                        next true if !other_op
                        op = ops.find do |o|
                            o == other_op
                        end
                        next false if !op
                        next true if op.base_class == self
                        next true if op.base_class == other_op.base_class
                        # ambiguous name look up due to multi
                        # inheritance
                        op.ambiguous_name = true
                        other_op.ambiguous_name = true
                        false
                    end
                    other_ops = other_ops.map(&:dup)
                    other_ops.each do |other|
                        old = other.alias
                        add_operation other
                    end
                end
            end
            # copy embedded arrays other wise they might get modified outside
            result = @operations.values.map(&:dup)
            @operations = own_ops
            result
        end

        def used_namespaces
            namespaces = super.clone
            parent_classes.each do |k|
                namespaces.merge k.used_namespaces
            end
            namespaces
        end

        def operation(name,raise_=true)
            ops = if @operations.has_key? name
                      @operations[name].dup
                  else
                      []
                  end
            parent_classes.each do |k|
                other_ops = Array(k.operation(name,false))
                other_ops.delete_if do |other_op|
                    ops.include? other_op
                end
                ops += other_ops
            end
            if(ops.size == 1)
                ops.first
            elsif ops.empty?
                raise "#{full_name} has no operation called #{name}." if raise_
            else
                ops
            end
        end

        def parent_classes
            @parent_classes.values
        end

        def parent_class(name)
            @parent_classes[name]
        end

        def pretty_print_name
            str = "class #{full_name}"
            unless parent_classes.empty?
                parents = parent_classes.map do |p|
                    p.full_name
                end
                str += " : " +  parents.join(", ")
            end
            str
        end

        def pretty_print(pp)
            super
        end

        def add_parent(klass)
            if @parent_classes.has_key? klass.name
                raise ArgumentError,"#A parent class with the name #{klass.name} already exists"
            end
            if klass.full_name == full_name || klass == self
                raise ArgumentError,"class #{klass.full_name} cannot be parent of its self"
            end
            # we have to disable the type check for the parent class 
            # otherwise derived types cannot be parsed
            klass.check_type = false
            @parent_classes[klass.name] = klass
            self
        end

        def parent_class(name)
            @parent_class[name]
        end
    end
end
