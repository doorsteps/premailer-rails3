class Premailer
  module Rails
    module CSSLoaders
      module Base
        # Extracts the path of a url.
        def extract_path(url)
          if url.is_a? String
            # Remove everything after ? including ?
            url = url[0..(url.index('?') - 1)] if url.include? '?'
            # Remove the host
            url = url.sub(/^https?\:\/\/[^\/]*/, '') if url.index('http') == 0
          end

          url
        end
      end


      # Loads the CSS from cache when not in development env.
      module CacheLoader
        extend Base
        extend self

        def load(url)
          path = extract_path(url)
          unless ::Rails.env.development?
            CSSHelper.cache[path]
          end
        end
      end

      module UrlLoader
        extend self

        def load(url)
          url = url.sub(/^\/\//, "https://")
          parsed_url = URI(url)
          if parsed_url.kind_of?(URI::HTTP)
            Net::HTTP.get(parsed_url).to_s
          else
            nil
          end
        end
      end

      # Loads the CSS from the asset pipeline.
      module AssetPipelineLoader
        extend Base
        extend self

        def load(url)
          path = extract_path(url)
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
        extend Base
        extend self

        def load(url)
          path = extract_path(url)
          File.read("#{::Rails.root}/public#{path}")
        end
      end
    end
  end
end
