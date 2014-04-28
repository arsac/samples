require 'active_support/concern'

module Filtering
	module Model
		extend ActiveSupport::Concern
		
		included do	
			class_eval do
				
				self.scope :letters do
					
					def available
						
						@letters ||= begin
						  
							#Get Where statement made by a letter filter so we can remove it
							by_letter_where = self.send(:except,:where).send(:by_letter,'*').where_clauses
							
							c = except(:by_letter,:offset, :limit, :order, :group)
              
							by_letter_where.map! { |str| 
								escaped = Regexp.escape(str.chomp(')').reverse.chomp('(').reverse).gsub('\*','.*?')
								Regexp.new "^#{escaped}$", Regexp::IGNORECASE
							}
							
							#remove where values that relate to the letter filter
							c.where_values.delete_if { |q| (q.is_a?(String) && by_letter_where.any? { |w| w.match(q) }) }

							ActiveRecord::Base.connection.execute c.available_by_letter.to_sql
						end
					end
				end
			end
    end

		module ClassMethods
						
			def order_by(column,direction)
				order("#{column} #{direction}")
			end
			
			def by_letter(letter = nil)
				
				if letter
					where("upper(#{self.table_name}.name) LIKE ?", letter.upcase + "%")
				else
					scoped
				end
			
			end
			
			def available_by_letter
				
				if self.column_names.include?("name")
					trim_name = "substr(upper(trim(#{self.table_name}.name)), 1,1)"  	
				  
				  select("#{trim_name} as letter")
				  .group(trim_name)
				
				else
					scoped
				end
			end
			
			def order_filter(field = false)
									
				table = field.split('.').first if (field.include?('.') && field.split('.').count > 1)
				col = table.nil? ? field : field.split('.').last
				
				if self.respond_to?("order_by_#{field}".to_sym)
					field = "order_by_#{field}".to_sym			
				elsif table && table != self.table_name
					
					association = self.reflect_on_association(table.to_sym) || self.reflect_on_association(table.singularize.to_sym)
					field = !association.nil? && association.klass.column_names.include?(col) ? field : false
				
				else
					field = self.column_names.include?(col) ? field : false
				
				end
			end
			
		end		
	end
end


ActiveRecord::Base.send(:include, Filtering::Model)