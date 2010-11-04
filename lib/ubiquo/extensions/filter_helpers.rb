#= How to include filters on Ubiquo listings
#
#FiltersHelper module provide some commonly used filters. By default, the module is included in <tt>app/helpers/ubiquo_area_helper.rb</tt>:
#
#  module UbiquoAreaHelper
#    include FiltersHelper
#    ...
#  end
#
#* The filter itself, containing the HTML that displays the filter on the lateral panel. It contains a header and a link to disable the filter when it is active.
#
#* The info filter that appears on top of the index listing. It displays textual info about all the active filters and contains a link to disable them all.
#
# Filters are automatically added to the index view, you only have to fill the helper (example for controller _articles_controller_):
#
#  # app/helpers/ubiquo/articles_helper.rb
#  module Ubiquo::ArticlesHelper
#    def article_filters
#       filters_for 'Article' do |f|
#         f.text
#         f.locale
#         f.date
#         f.select :name, @collection
#         f.boolean :status
#       end
#    end
#  end
#
#  # app/views/ubiquo/articles/index.html.erb
#  <h1>
#    <%= render :partial => 'title' %>
#  </h1>
#
#  <h2>
#    <%= render :partial => 'submenu' %>
#  </h2>
#
#  <%= render :partial => "shared/ubiquo/feedback" %>
#
#  <%=
#      show_filter_info # To render filter messages
#  %>
#
#  <%= article_list(@articles, @articles_pages) %>
#
#  <% content_for :sidebar do %>
#    <%=
#        show_filters # To render filters
#    %>
#    <h3><%= t("ubiquo.help") %></h3>
#    <p><%= t("ubiquo.article.index.help_message") %></p>
#  <% end %>
#
#
#== Text filter
#
#link:../images/filter_string.png
#
#It consists of an input text tag with a search button. Default options are shown.
#
#  f.text :field           => :description,            # Filter param name
#         :url_for_options => {}                       # Hash to be merged with filter params
#         :caption         => t('ubiquo.filters.txt')  # Text to display for this filter
#
#  f.text # Does the same as the above one.
#
#== Links filter
#
#link:../images/filter_link.png
#
#Given an attribute to filter, generate a link for each possible value. There are two common cases:
#
#* You have a separated model (one-to-many relationship). On this case, you have to pass the collection of values and the associated model tablename (plural, underscore form).
#
#  f.link :type,
#         @asset_types,
#         :id_field    => :id,
#         :name_field  => :name,
#         :caption     => t('type'),
#
# Default values are:
#
#  :field       => "filter_#{field}".to_sym,
#  :collection  => collection,
#  :id_field    => :id,
#  :name_field  => default_name_field, # It will check for :name or :title existance
#  :caption     => @model.human_attribute_name(field),
#
# So you could use something like:
#
# f.link :type, @asset_types
#
#* The possible values for an attribute but directly a list of them on the model. Let's see an example:
#
#  class Link
#    TARGET_OPTIONS = [[t("Link|blank"), "blank"], [t("Link|self"), "self"]]
#    validates_inclusion_of :target, :in => TARGET_OPTIONS.map { |name, key| key }
#  end
#
#
#  # On the controller
#  @target_types = Link::TARGET_OPTIONS.collect do |name, value|
#    OpenStruct.new(:name => name, :value => value)
#  end
#
#  f.link :type,
#         @target_types,
#         :id_field => :value,
#         :caption => t('type'),
#         :translate_prefix => 'Link'
#
#
#== Select filter
#
#link:../images/filter_select_1.png
#
#link:../images/filter_select_2.png
#
#Generate a select tag given an array of items.
#
#It works exactly on the same way than the links filter, only that an extra option (options[:all_caption]) is needed to add a "all" option that disables the filter:
##
#  f.select :type,
#           @asset_types,
#           :id_field    => :id,
#           :name_field  => :name,
#           :caption     => t('type'),
#           :all_caption => t('-- All --')
#
#
#== Links or Select filter
#
#This filter renders a select filter if the collection items length is greater than ''options[:max_size_for_links]''; it uses a link filter otherwise. Pass the same options needed by a select filter. An example of the filter info code:
#
#
#  f.links_or_select :type,
#                    @asset_types,
#                    :id_field    => :id,
#                    :name_field  => :name,
#                    :caption     => t('type'),
#                    :all_caption => t('-- All --'),
#                    :max_size_for_links => 2
#
#
#== Boolean Filter
#
#link:../images/bolean_filter.png
#
#For boolean attributes use a link or select filter, but instead of ''collection/id_field/name_field'' options, pass ''boolean/caption_true/caption_false''.
#
#  f.boolean :admin,
#            :caption => t('ubiquo_user type'),
#            :caption_true => t('Admin'),
#            :caption_false => t('Non-admin')
#            :options_for_url => params
#
# Default values are:
#  :field         => "filter_#{field}",
#  :caption       => @model.human_attribute_name(field),
#  :caption_true  => I18n.t('ubiquo.filters.boolean_true'),
#  :caption_false => I18n.t('ubiquo.filters.boolean_false'),
#
#
#== Date filter
#
#link:../images/date_filter_1.png
#link:../images/date_filter_2.png
#
#Date filters employ the plugin [http://code.google.com/p/calendardateselect/ calendardateselect]. If you need to change the stylesheets, edit <tt>public/stylesheets/calendar_date_select/ubiquo.css</tt>. To use the lateral filter on your listing, you have to indicate the caption and the start/end date field names:
#
#  f.date :field => [:date_start, :date_end],
#         :caption => t('creation'),
#
# Default values are:
#
#  :field       => [:filter_publish_start, :filter_publish_end],
#  :caption     => @model.human_attribute_name(field)
#
#
#== Single Date filter
# Used to filter with only one date. It's like last filter but with just one date field:
#
#  f.date :field => :date,
#         :caption => t('creation')
#
# Default values are:
#
#  :field => :filter_publish_end,
#  :caption => @model.human_attribute_name(field)
#

module Ubiquo
  module Extensions
    module FilterHelpers

      class UbiquoFilterError < StandardError; end
      class UnknownFilter < UbiquoFilterError; end
      class MissingFilterSetDefinition < UbiquoFilterError; end

      class FilterSetBuilder

        attr_reader :filters

        def initialize(model, context)
          @model = model.constantize
          @context = context
          @filters = []
        end

        def method_missing(method, *args, &block)
          filter = get_filter_class(method).new(@model, @context)
          filter.configure(*args,&block)
          @filters << filter
        end

        # Renders all filters of the set, in order, as a string
        def render
          @filters.map { |f| f.render }.join("\n")
        end

        # Renders the human message, associated with active filters of
        # the set, as a string
        def message
          info_messages = @filters.inject([]) do |result, filter|
            result << filter.message
          end
          build_filter_info(info_messages)
        end

        # TODO: Make private in ubiquo 0.9.0. Public for now to
        # maintain the deprecated interface.
        def build_filter_info(info_messages)
          fields, string = process_filter_info(info_messages)
          return unless fields
          info = @context.content_tag(:strong, string)
          # Remove keys from applied filters and other unnecessary keys (commit, page, ...)
          remove_fields = fields + [:commit, :page]
          new_params = @context.params.clone
          remove_fields.each { |field| new_params[field] = nil }
          link_text = "[" + I18n.t('ubiquo.filters.remove_all_filters', :count => fields.size) + "]"
          message = [ I18n.t('ubiquo.filters.filtered_by', :field => info), @context.link_to(link_text, new_params)]
          @context.content_tag(:p, message.join(" "), :class => 'search_info')
        end

        private

        # Return the pretty filter info string
        #
        # info_and_fields: array of [info_string, fields_for_that_filter]
        def process_filter_info(info_and_fields)
          info_and_fields.compact!
          return if info_and_fields.empty?
          # unzip pairs of [text_info, fields_array]
          strings, fields0 = info_and_fields[0].zip(*info_and_fields[1..-1])
          fields = fields0.flatten.uniq
          [fields, string_enumeration(strings)]
        end

        # From an array of strings, return a human-language enumeration
        def string_enumeration(strings)
          strings.reject(&:empty?).to_sentence()
        end

        # Given a filter_for method name returns the appropiate filter class
        def get_filter_class(filter_name)
          camel_cased_word = "Ubiquo::Extensions::FilterHelpers::#{filter_name.to_s.classify}Filter"
          camel_cased_word.split('::').inject(Object) do |constant, name|
            constant = constant.const_get(name)
          end
        end

      end

      # Defines a filter set. For example:
      #  # app/helpers/ubiquo/articles_helper.rb
      #  module Ubiquo::ArticlesHelper
      #    def article_filters
      #       filters_for 'Article' do |f|
      #         f.text
      #         f.locale
      #         f.date
      #         f.select :name, @collection
      #         f.boolean :status
      #       end
      #    end
      #  end
      def filters_for(model,&block)
        raise ArgumentError, "Missing block" unless block
        filter_set = FilterSetBuilder.new(model, self)
        yield filter_set
        @filter_set = filter_set
      end

      # Render  a filter set
      def show_filters
        initialize_filter_set_if_needed
        @filter_set.render
      end

      # Render a filter set human message
      def show_filter_info
        initialize_filter_set_if_needed
        @filter_set.message
      end

      # TODO: The following public methods should be deprecated in the
      # 0.9.0 release

      # Render a lateral filter
      #
      # filter_name (symbol): currently implemented: :date_filter, :string_filter, :select_filter
      # url_for_options: route used by the form (string or hash)
      # options_for_filter: options for a filter (see each *_filter_info helpers for details)
      def render_filter(filter_name, url_for_options, options = {})
        deprecation_message
        options[:url_for_options] = url_for_options
        filter_name = :boolean if options[:boolean]
        filter = select_filter(filter_name, options)
        filter.render
      end

      # Return the informative string about a filter process
      #
      # filter_name (symbol). Currently implemented: :date_filter, :string_filter, :select_filter
      # params: current 'params' controller object (hash)
      # options_for_filter: specific options needed to build the filter string (hash)
      #
      # Return array [info_string, fields_used_by_this_filter]
      def filter_info(filter_name, params, options = {})
        deprecation_message
        filter = select_filter(filter_name, options)
        filter.message
      end

      # Return the pretty filter info string
      #
      # info_and_fields: array of [info_string, fields_for_that_filter]
      def build_filter_info(*info_and_fields)
        deprecation_message
        model = self.controller_name.classify
        fs = FilterSetBuilder.new(model, self)
        fs.build_filter_info(info_and_fields)
      end

      private

      # Initializes filter set definition if it isn't already.
      # We need to do this because sometimes we need to render the
      # messages before filters are defined.
      # So if we don't have a filter set we try to run the helper
      # method we expect that will define them.
      #
      # Ex: For the articles_controller we will execute the
      # article_filters method to load the filter set definition.
      #
      # Thanks to this trick we avoid to define filters two times one
      # for messages and one for render.
      def initialize_filter_set_if_needed
        helper = "#{@controller.controller_name.singularize}_filters"
        send(helper) unless @filter_set
      end

      # Transitional method to maintain compatibility with the old
      # filter interface.
      # TODO: To be removed from the 0.9.0 release
      def select_filter(name, options)
        model = self.controller_name.classify.constantize
        field = options[:field]
        case name
        when :single_date
          returning(SingleDateFilter.new(model, self)) { |f| f.configure(options) }
        when :date
          returning(DateFilter.new(model, self)) { |f| f.configure(options) }
        when :string
          returning(TextFilter.new(model, self)) { |f| f.configure(options) }
        when :select
          returning(SelectFilter.new(model, self)) { |f| f.configure(field, options[:collection], options) }
        when :links
          returning(LinkFilter.new(model, self)) { |f| f.configure(field, options[:collection], options) }
        when :links_or_select
          returning(LinksOrSelectFilter.new(model, self)) { |f| f.configure(field, options[:collection], options) }
        when :boolean
          returning(BooleanFilter.new(model, self)) { |f| f.configure(field, options)}
        end
      end

      # Transitional method to maintain compatibility with the old
      # filter interface.
      # TODO: To be removed from the 0.9.0 release
      def deprecation_message
        caller_method_name = caller.first.scan /`([a-z_]+)'$/
        msg = "DEPRECATION WARNING: #{caller_method_name} will be removed in 0.9.0. See http://guides.ubiquo.me/edge/ubiquo_core.html for more information."
        ActiveSupport::Deprecation.warn(msg)
      end

    end
  end
end
