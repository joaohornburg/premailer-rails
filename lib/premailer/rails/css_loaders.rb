require 'httparty'

class Premailer
  module Rails
    module CSSLoaders
      
      module HTTPLoader
        extend self
        
        def load(path)
          include HTTParty
          begin
            uri = URI.parse(path)
            if exitsts?(uri)
              HTTParty.get(uri.to_s).body
            end
          rescue
          end
        end
        
        private
        
        def exitsts?(uri)
    			request = Net::HTTP.new(uri.host, uri.port)
    			res = request.request_head(uri.to_s)
    			return ['200','302'].include? res.code
        end
      end
      
      # Loads the CSS from cache when not in development env.
      module CacheLoader
        extend self

        def load(path)
          unless ::Rails.env.development?
            CSSHelper.cache[path]
          end
        end
      end

      # Loads the CSS from the asset pipeline.
      module AssetPipelineLoader
        extend self

        def load(path)
          if assets_enabled?
            file = file_name(path)
            if asset = ::Rails.application.assets.find_asset(file)
              asset.to_s
            else
              request_and_unzip(file)
            end
          end
        end

        def assets_enabled?
          ::Rails.configuration.assets.enabled rescue false
        end

        def file_name(path)
          path
            .sub("#{::Rails.configuration.assets.prefix}/", '')
            .sub(/-\h{32}\.css$/, '.css')
        end

        def request_and_unzip(file)
          url = [
            ::Rails.configuration.action_controller.asset_host,
            ::Rails.configuration.assets.prefix.sub(/^\//, ''),
            ::Rails.configuration.assets.digests[file]
          ].join('/')
          response = Kernel.open(url)

          begin
            Zlib::GzipReader.new(response).read
          rescue Zlib::GzipFile::Error, Zlib::Error
            response.rewind
            response.read
          end
        end
      end

      # Loads the CSS from the file system.
      module FileSystemLoader
        extend self

        def load(path)
          File.read("#{::Rails.root}/public#{path}")
        end
      end
    end
  end
end
