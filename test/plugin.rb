class Fluent::DNSResolverTestXOutput < Fluent::Output
  Fluent::Plugin.register_output('dns_resolver_test_x', self)

  include Fluent::Mixin::DNSResolver

  ###TODO: write
end
