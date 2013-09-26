require 'open-uri'
require 'zlib'

class Premailer
  module Rails
    module CSSHelper
      extend self

      @cache = {}
      attr :cache

      STRATEGIES = [
        CSSLoaders::CacheLoader,
        CSSLoaders::UrlLoader,
        CSSLoaders::AssetPipelineLoader,
        CSSLoaders::FileSystemLoader
      ]

      # Returns all linked CSS files concatenated as string.
      def css_for_doc(doc, strategies = STRATEGIES)
        urls = css_urls_in_doc(doc)
        urls.map { |url| load_css(url, strategies) }.join("\n")
      end

      private

      def css_urls_in_doc(doc)
        doc.search('link[@type="text/css"]').map do |link|
          link.attributes['href'].to_s
        end
      end

      def load_css(url, strategies = STRATEGIES)
        @cache[url] = strategies.each do |strategy|
                         css = strategy.load(url)
                         break css if css
                       end
      end
    end
  end
end
