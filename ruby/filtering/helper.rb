require 'active_support/concern'

module Filtering
	module Helper
		extend ActiveSupport::Concern
		
		included do
			
				def sort_column(column = nil, label = nil)
					
					label ||= column.to_s
					
					options = Hash.new
					link_class = "inactive"

					order_by_column_name = order_by_column.to_s.gsub("order_by_","")					
					options[:order_by] = column
					options[:sort_direction] = order_by_direction == "asc" ? "desc" : "asc"
					
					if column == order_by_column_name
						link_class = "active"
						label << "&nbsp;"
						if order_by_direction == "asc"
							options[:sort_direction] = "desc"
							label << content_tag(:i, '', :class=>'icon-caret-down')
						else
							options[:sort_direction] = "asc"
							label << content_tag(:i, '', :class=>'icon-caret-up')
						end
					end
					link_class << " #{@order_by_direction}"
					
					link_to(label.html_safe,params.merge(options), :class => link_class)
				end
				
				def alphabet_filter(q, options = {})
					a=*("A".."Z")
					
					params_clone = params.clone
					params_clone.delete_if {|k,v| [:by_letter,:page].include?(k.to_sym)}
										
					add = []

					available_letters = [].tap do |av| 
						q.letters.available.each do |l|
							av << l[0] unless l.nil?
							
							unless a.include?(l[0])
							
								add << l[0]
							end
						end
					end
					
					unless add.empty?
						a = add + a
					end
					
					content_tag :nav, :class => "pagination" do
						content_tag :ul, :class => 'alphabet-filter' do
							content_tag(:li,link_to("All",params_clone,options), :class =>  params[:by_letter].blank? ? "active" : ""  ) + a.collect do |item|
								_li_class = []
								_li_class << "active" if params[:by_letter] == item
								path = "javascript:void(0)"
								
								link_options = {}
								
								if !available_letters.nil? && available_letters.include?(item)
									params_clone[:by_letter] = item
									path = params_clone
									link_options = options
								else
									_li_class << "disabled"
								end

								content_tag(:li, :class => _li_class ) do
									link_to(item.html_safe,path, link_options)
								end
							end.join.html_safe
						end
					end
				end
				
		end
	
	end
end

Admin::AdminHelper.send(:include, Filtering::Helper)