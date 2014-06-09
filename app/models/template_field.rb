class TemplateField < ActiveRecord::Base
	belongs_to :template
	
	include RankedModel
	ranks :field_order, with_same: :template_id
	
	scope :editable, -> {where editable: true}
	
end
