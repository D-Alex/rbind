        # wrapper for <%= signature %>
        if args.size == <%= parameters.size %>
            return Rbind::<%= cname %>(*args)
        end
