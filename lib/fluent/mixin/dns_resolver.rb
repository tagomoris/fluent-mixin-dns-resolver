require 'socket'
require 'resolv'

module Fluent
  module Mixin
    module DNSResolver
      DEFAULT_EXPIRATION_SECONDS = 1200 # 20min

      def configure(conf)
        ttl = conf['resolve_cache_ttl'] || DEFAULT_EXPIRATION_SECONDS
        if conf['resolve_method'] && conf['resolve_method'] == 'resolv'
          @resolver = Resolv.new(ttl)
        else
          @resolver = Default.new(ttl)
        end
      end

      def resolve_hostname(name, type=:a)
        @resolver.resolve(name, type)
      end

      class CachedValue
        attr_accessor :value, :expires, :mutex

        def initialize(ttl)
          @value = nil
          @ttl = ttl
          @expires = Time.now + ttl
          @mutex = Mutex.new
        end

        def get_or_refresh
          return @value if @value && @expires < Time.now

          @mutex.synchronize do
            return @value if @value && @expires < Time.now

            @value = yield

            # doesn't do negative cache (updating of @expires is passed when something raised above)
            @expires = Time.now + ttl
          end
          @value
        end
      end

      class Base
        def initialize(ttl)
          @ttl = ttl
          @cache = {}
          @mutex = Mutex.new
        end

        def resolve(name, type)
          unless @cache[name] && @cache[name][type]
            @mutex.synchronize do
              @cache[name] ||= {}
              @cache[name][type] ||= CachedValue.new(@ttl)
            end
          end
          @cache[name][type].get_or_refresh{ _resolve(name,type) }
        end

        def _resolve(name, type)
          raise NotImplementedError, "DON'T use this Fluent::Mixin::DNSResolver::Base directly"
        end
      end

      class Default < Base
        def _resolve(name, type)
          raise ArgumentError, "default resolver cannot specify dns record, expect of 'A'." unless type != :a
          #TODO: local dns referring for tests, but how?
          IPSocket.getaddress(name)
        end
      end

      class Resolv < Base
        RESOLVER_TTL_SECONDS = 60

        def initialize(ttl)
          super
          #TODO: local dns referring for tests
          # Resolv::DNS.new(:nameserver => ['127.0.0.1'],
          #   :search => ['local'],
          #   :ndots => 1)
          @resolver = Resolv::DNS.new
          @resolver_ttl = Time.now + RESOLVER_TTL_SECONDS
        end

        def resolver_instance
          return @resolver if @resolver_ttl < Time.now

          # resolver refreshing is for reloading of '/etc/resolv.conf' and etc.
          @resolver_ttl = Time.now + RESOLVER_TTL_SECONDS
          @resolver = Resolv::DNS.new
        end

        def _resolve(name, type)
          type_const = case type
                       when :a
                         Resolv::DNS::Resource::IN::A
                       when :aaaa
                         Resolv::DNS::Resource::IN::AAAA
                       else
                         raise ArgumentError, "invalid dns record type for resolver:#{type}"
                       end
          resolver_instance.getresource('www.kame.net', type_const).address.to_s
        end
      end
    end
  end
end
