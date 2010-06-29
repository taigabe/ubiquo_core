require 'ostruct'

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
# Filters are automatically added to the index view, you only have to fill the helper (example for controller _example_controller_):
#
#  # app/helpers/ubiquo/example_helper.rb 
#  module Ubiquo::UbiquoUsersHelper
#    def ubiquo_users_filters_info(params)
#       # Put your filters info here (filter_info)
#    end
#
#    def ubiquo_users_filters(url_for_options = {})
#       # Put your filters here (render_filter)
#    end
#
#  end
#
#
#== String filter
#
#link:../images/filter_string.png
#
#It consists of an input text tag with a search button.
#
#  string_filter = render_filter(:string, {},
#    :field => :filter_text,
#    :caption => t('text'))
#
#First parameter is the filter name (:string) and the second is the ''url_for_options'' hash that will be merged with the filter params. If you want to submit the filter to the same action/controller you are in, simply pass an empty hash.
#
#  string_filter = filter_info(:string, params,
#    :field => :filter_text,
#    :caption => t('text'))
#    
#  build_filter_info(string_filter)                                
#
#== Links filter
#
#link:../images/filter_link.png
#
#Given an attribute to filter, generate a link for each possible value. There are two common cases:
#
#* You have a separated model (one-to-many relationship). On this case, you have to pass the collection of values and the associated model tablename (plural, underscore form).
#
#    asset_types_filter = render_filter(:links, {},
#    :caption => t('type'),
#      :all_caption => t('-- All --'),
#      :field => :filter_type,
#      :collection => @asset_types,
#      :id_field => :id,
#      :name_field => :name)
#    
#    build_filter_info(asset_types_filter)
#    ---  
#    asset_types_filter = filter_info(:links, params,
#      :caption => t('type'),
#      :all_caption => t('-- All --'),
#      :field => :filter_type,
#      :collection => @asset_types,
#      :model => :asset_types,
#      :id_field => :id,
#      :name_field => :name)
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
#  # On the view
#  asset_types_filter = render_filter(:links, {},
#    :caption => t('type'),
#    :field => :filter_type,
#    :collection => @target_types, 
#    :id_field => :value,
#    :name_field => :name)  
#
#  asset_types_filter = filter_info(:links, params,
#    :caption => t('target'),
#    :field => :filter_type,
#    :translate_prefix => 'Link')
#    
#  build_filter_info(asset_types_filter)  
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
#
#  asset_types_filter = render_filter(:select, {},
#    :caption => t('type'),
#    :all_caption => t('-- All --'),
#    :field => :filter_type,
#    :collection => @asset_types,
#    :id_field => :id,
#    :name_field => :name)
#    
#  build_filter_info(asset_types_filter)  
#
#== Links or Select filter
#
#This filter renders a select filter if the collection items length is greater than ''options[:max_size_for_links]''; it uses a link filter otherwise. Pass the same options needed by a select filter. An example of the filter info code:
#
#  asset_types_filter = render_filter(:links_or_select, {},
#    :caption => t('type'),
#    :all_caption => t('-- All --'),
#    :field => :filter_type,
#    :collection => @asset_types,
#    :id_field => :id,
#    :name_field => :name,
#    :max_size_for_links => 2)
#    
#  build_filter_info(asset_types_filter)  
#
#== Boolean Filter
#
#link:../images/bolean_filter.png
#
#For boolean attributes use a link or select filter, but instead of ''collection/id_field/name_field'' options, pass ''boolean/caption_true/caption_false''.
#
#  admin_filter = render_filter(:links, {},
#    :caption => t('ubiquo_user type'),
#    :boolean => true,
#    :caption_true => t('Admin'),
#    :caption_false => t('Non-admin'),
#    :field => :filter_admin)
#  ---
#  admin_filter = filter_info(:links, params,
#    :caption => t('ubiquo_user type'),
#    :boolean => true,
#    :caption_true => t('Admin'),
#    :caption_false => t('Non-admin'),
#    :field => :filter_admin)
#    
#  build_filter_info(admin_filter)
#
#== Date filter
#
#link:../images/date_filter_1.png
#link:../images/date_filter_2.png
#
#Date filters employ the plugin [http://code.google.com/p/calendardateselect/ calendardateselect]. If you need to change the stylesheets, edit <tt>public/stylesheets/calendar_date_select/ubiquo.css</tt>. To use the lateral filter on your listing, you have to indicate the caption and the start/end date field names:
#
#  date_filter = render_filter(:date, {},
#    :caption => t('creation'),
#    :field => [:date_start, :date_end])
#  ---
#  date_filter = filter_info(:date, params,
#    :caption => t('creation'),
#    :field => [:date_start, :date_end])
#  
#  build_filter_info(date_filter)
#
#== Single Date filter
# Used to filter with only one date. It's like last filter but with just one date field:
#
#  date_filter = render_filter(:single_date, {},
#    :caption => t('creation'),
#    :field => :filter_date)
#  ---
#  date_filter = filter_info(:single_date, params,
#    :caption => t('creation'),
#    :field => :filter_date)
#  
#  build_filter_info(date_filter)

module Ubiquo
  module Extensions
    module FiltersHelper
      def lateral_filter(title, fields=[], &block)
        content = capture(&block)
        concat(render(:partial => "shared/ubiquo/lateral_filter", 
                      :locals => {:title => title, 
                        :content => content, 
                        :fields => [fields].flatten}))
      end
      
      # Render a lateral filter
      #
      # filter_name (symbol): currently implemented: :date_filter, :string_filter, :select_filter
      # url_for_options: route used by the form (string or hash)
      # options_for_filter: options for a filter (see each *_filter_info helpers for details)
      def render_filter(filter_name, url_for_options, options_for_filter = {})
        if options_for_filter[:boolean]
          # Build a mock :collection object (use OpenStruct for simplicity)
          options_for_filter[:collection] = [
                                             OpenStruct.new(:option_id => 0, :name => options_for_filter[:caption_false]),
                                             OpenStruct.new(:option_id => 1, :name => options_for_filter[:caption_true]),        
                                            ]
          # Don't use :id as :id_field but, as :id is internally used by Ruby and will fail
          options_for_filter.update(:id_field => :option_id, :name_field => :name)
        end
        
        partial_template = case filter_name.to_sym 
                           when :links_or_select
                             if options_for_filter[:collection].size <= (options_for_filter[:max_size_for_links] || Ubiquo::Config.get(:max_size_for_links_filter))
                               "shared/ubiquo/filters/links_filter" 
                             else 
                               "shared/ubiquo/filters/select_filter" 
                             end
                           else
                             "shared/ubiquo/filters/#{filter_name}_filter" 
                           end    
        
        link = params.reject do |key, values|
          filter_fields = [options_for_filter[:field]].flatten.map(&:to_s)
          toremove = %w{commit controller action page} + filter_fields
          toremove.include?(key)
        end.to_hash
        
        locals = {
          :partial_locals => {
            :options => options_for_filter,
            :url_for_options => url_for_options, 
            :link => link,
          },
          :partial => partial_template,
        }
        render :partial => "shared/ubiquo/filters/filter", :locals => locals  
      end
      
      # Return the informative string about a filter process
      #
      # filter_name (symbol). Currently implemented: :date_filter, :string_filter, :select_filter
      # params: current 'params' controller object (hash)
      # options_for_filter: specific options needed to build the filter string (hash)
      #
      # Return array [info_string, fields_used_by_this_filter]
      def filter_info(filter_name, params, options_for_filter = {})
        helper_method = "#{filter_name}_filter_info".to_sym
        raise "Filter helper not found: #{helper_method}" unless self.respond_to?(helper_method, true) 
        info_string, fields0 = send(helper_method, params, options_for_filter)
        return unless info_string && fields0 
        fields = fields0.flatten.uniq
        [info_string, fields] 
      end

      # Return the pretty filter info string
      #
      # info_and_fields: array of [info_string, fields_for_that_filter]
      def build_filter_info(*info_and_fields)
        fields, string = process_filter_info(*info_and_fields)
        return unless fields
        info = content_tag(:strong, string)
        # Remove keys from applied filters and other unnecessary keys (commit, page, ...)
        remove_fields = fields + [:commit, :page]
        new_params = params.clone
        remove_fields.each { |field| new_params[field] = nil }
        link_text = "[" + t('ubiquo.filters.remove_all_filters', :count => fields.size) + "]"
        message = [ t('ubiquo.filters.filtered_by', :field => info), link_to(link_text, new_params)]
        content_tag(:p, message.join(" "), :class => 'search_info')
      end
      
      # Return the pretty filter info string
      #
      # info_and_fields: array of [info_string, fields_for_that_filter]
      def process_filter_info(*info_and_fields)
        info_and_fields.compact!
        return if info_and_fields.empty?
        # unzip pairs of [text_info, fields_array]
        strings, fields0 = info_and_fields[0].zip(*info_and_fields[1..-1])
        fields = fields0.flatten.uniq
        [fields, string_enumeration(strings)]
      end

      private

      # Return info to show a informative string about a date search
      #
      # Return an array [text_info, array_of_fields_used_on_that_filter]
      def single_date_filter_info(filters, options_for_filter)
        date_field = options_for_filter[:field].to_sym
        date = filters[date_field]
        
        return unless date
        info = t('ubiquo.filters.filter_simple_date', :date => date)
        
        info = options_for_filter[:caption] + " " + info if options_for_filter[:caption] 
        [info, [date_field]]
      end

      # Return info to show a informative string about a date search
      #
      # Return an array [text_info, array_of_fields_used_on_that_filter]
      def date_filter_info(filters, options_for_filter)
        date_start_field, date_end_field = options_for_filter[:field].map(&:to_sym)
        process_date = Proc.new do |key|
          filters[key] if !filters[key].blank? #&& is_valid_date?(filters[key])
        end
        date_start = process_date.call(date_start_field)
        date_end = process_date.call(date_end_field)
        return unless date_start or date_end
        info = if date_start and date_end
                 t('ubiquo.filters.filter_between', :date_start => date_start, :date_end => date_end)
               elsif date_start
                 t('ubiquo.filters.filter_from', :date_start => date_start)
               elsif date_end
                 t('ubiquo.filters.filter_until', :date_end => date_end)
               end
        info2 = options_for_filter[:caption] + " " + info if options_for_filter[:caption] 
        [info2, [date_start_field, date_end_field]]
      end

      # Return info to show a informative string about a string search
      #
      # filters: hash containing
      #   :filter_string
      #
      # Return an array [text_info, array_of_fields_used_on_that_filter]  
      def string_filter_info(filters, options_for_filter)
        field = options_for_filter[:field].to_s
        string = !filters[field].blank? && filters[field]
        return unless string
        info = options_for_filter[:caption].blank? ? 
          t('ubiquo.filters.filter_text', :string => string) : 
          "#{options_for_filter[:caption]} '#{string}'"
        [info, [field]]
      end

      # Return info to show a informative string about a selection filter
      #
      # filters: hash containing filter keys
      #
      # options_for_filters: Default select (non-boolean)
      #   field: field name (symbol)
      #   id_field: attribute of the record to search the field value (symbol)
      #   name_field: field of the record to be shown (symbol)
      #   model: model name where the search has been made (symbol or string)
      #
      # options_for_filters Boolean selection
      #   boolean: true
      #   caption_true: message when selection is true
      #   caption_false: message when selection is false
      #   
      # Return an array [text_info, array_of_fields_used_on_that_filter]  
      def select_filter_info(filters, options_for_filter)
        field_key = options_for_filter[:field] || raise("options_for_filter: missing 'field' key")
        field = !filters[field_key].blank? && filters[field_key]
        return unless field
        name = if options_for_filter[:boolean]
                 caption_true = options_for_filter[:caption_true] || raise("options_for_filter: missing 'caption_true' key")
                 caption_false = options_for_filter[:caption_false] || raise("options_for_filter: missing 'caption_false' key")
                 (filters[field_key] == "1") ? caption_true : caption_false  
               else
                 if options_for_filter[:model]
                   id_field = options_for_filter[:id_field] || raise("options_for_filter: missing 'id_field' key")
                   model = options_for_filter[:model].to_s.classify.constantize
                   record = model.find(:first, :conditions => {id_field => filters[field_key]})
                   return unless record
                   name_field = options_for_filter[:name_field] || raise("options_for_filter: missing 'name_field' key")
                   record.send(name_field)
                 elsif options_for_filter[:collection]
                   value = options_for_filter[:collection].find do |value| 
                     value.send(options_for_filter[:id_field]).to_s == filters[field_key]
                   end.send(options_for_filter[:name_field]) rescue filters[field_key]
                 else
                   prefix = options_for_filter[:translate_prefix]
                   prefix ? t("#{prefix}.filters.#{filters[field_key]}") : filters[field_key]
                 end
               end
        info = "#{options_for_filter[:caption]} '#{name}'"
        [info, [field_key]]    
      end

      # Return info to show a informative string about a link filter
      def links_filter_info(filters, options_for_filter)
        select_filter_info(filters, options_for_filter)
      end

      # Return info to show a informative string about a links_or_select filter
      def links_or_select_filter_info(filters, options_for_filter)
        select_filter_info(filters, options_for_filter)
      end
      
      # From an array of strings, return a human-language enumeration
      def string_enumeration(strings)
        strings.reject(&:empty?).to_sentence()
      end
      
      def build_hidden_field_tags(hash)
        hash.map do |field, value| 
          if value.is_a? Array
            value.map {|val| hidden_field_tag field+"[]", val}.flatten
          else
            hidden_field_tag field, value, :id => nil
          end
        end.join("\n")
      end 
      
    end
  end
end
