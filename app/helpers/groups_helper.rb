# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


module GroupsHelper
	
	# Cache key for group reated stuff
	def group_cache_key(group)
		group.cache_key + current_user.cache_key
	end
	
	# Construct a link to a group with basic group infor
	def group_link_tag(g)
		html = 'Group: ' 
		html << link_to(g.name, group_path(g), { name: "group_#{g.id}" } )
		html << " Slides: #{g.slides.published.count}/#{g.slides.count}" 
		return html.html_safe
	end
	
end
