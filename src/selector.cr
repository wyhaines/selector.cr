require "./selector_impl"

selector = Selector.new(*Selector.parse_setup)
selector.run
