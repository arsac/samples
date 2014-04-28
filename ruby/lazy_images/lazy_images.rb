module ActionView
  module Helpers
    module AssetTagHelper

      def image_tag_with_laziness(source, options={})
        options = options.symbolize_keys
        orig_source = source
        
        options[:lazy] ||= false
        is_lazy = options[:lazy]
        options.delete(:lazy)

		    if is_lazy

          options[:data] ||= {}
          options[:data].merge!({ :src => path_to_image(orig_source)})
          options[:class] ||= []
          options[:class] = options[:class].is_a?(Array) ? options[:class] : options[:class].join(" ")

          options[:lazy_source] ||= "blank.gif"
          options[:lazy_class] ||= "lazy"

          options[:class] << options[:lazy_class]

          source = options[:lazy_source]

          options.delete(:lazy_source)
          options.delete(:lazy_class)

          orig_options = options.dup
        end

        output = image_tag_without_laziness(source, options)
        output << content_tag('noscript', image_tag_without_laziness(orig_source, orig_options)) if is_lazy
        output
      end

      alias_method_chain :image_tag, :laziness
    end
  end
end