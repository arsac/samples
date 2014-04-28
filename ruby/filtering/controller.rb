require 'active_support/concern'

module Filtering
	module Controller
		extend ActiveSupport::Concern
		
		included do
			hide_action :order_by_key
			hide_action :order_by_direction
			hide_action :order_by_column
			
			helper_method :order_by_column
			helper_method :order_by_direction

			has_scope :by_letter			
			has_scope :order_by do |controller, scope, value|

				controller.send(:order_by_column,scope.order_filter(value))
				
				if controller.order_by_column.is_a?(Symbol) && scope.respond_to?(controller.order_by_column)
					scope.send(controller.order_by_column,controller.order_by_direction)
				elsif controller.order_by_column
					scope.order_by(controller.order_by_column, controller.order_by_direction )
				else
					scope.scoped
				end
			end
		end
		
		def order_by_direction
			@order_by_direction ||= %w[asc desc].include?(params[:sort_direction]) ? params[:sort_direction] : "asc"
		end
		def order_by_column(column = nil)
			@order_by_column ||= column
		end

	end
end

Admin::AdminController.send(:include, Filtering::Controller)