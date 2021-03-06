# 
#  image_slide.rb
#  isk
#  
#  Created by Vesa-Pekka Palmu on 2014-06-19.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
# 

class	ImageSlide < Slide
	TypeString = "image"
	
	ScalingOptions = [
		['Fit', 'fit'],
		['Down only', 'down'],
		['Up only', 'up'],
		['Stretch', 'stretch']
	]
	
	DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(
		scale: 'fit',
		background: '#000000'
	)
	include HasSlidedata
	
	after_save :save_image
	validate :check_image
	validate :check_bg_color

	# Receive a new slide image.
	# Since we might not have a ID yet just store it in a temp file for now.
	def image=(image)
		file = Tempfile.new('isk-image', encoding: 'binary')
		file.write(image.read)
		file.close
		@_image_file = file
	end
		
	private
	
	# A after save hook to move the possible new image into its place
	def save_image
		if @_image_file
			FileUtils.move @_image_file.path, self.original_filename
			@_image_file = nil
		end
	end
	
	# Validate the uploaded image.
	def check_image
		if @_image_file
			# Verify image integrity
			command = "identify #{@_image_file.path} &> /dev/null"
			unless system command
				@_image_file.unlink
				@_image_file = nil
				errors.add :image, "wasn't a valid image file."
			end
		end
	end
	
	# Validates that the background color is ok
	def check_bg_color
		unless slidedata[:background].match /\A#(?:[0-9a-f]{3})(?:[0-9a-f]{3})?\z/
			errors.add :backgroud, 'must be valid css hex color'
		end
	end
	
	# Generate the full size slide preview
	def generate_full_image
		bg_color = self.slidedata[:background]
		scale = self.slidedata[:scale]
		size = picture_sizes[:full].join('x')
		
		# Build the ImageMagick geometry string
		# The string is WIDTHxHEIGHT + scaling operator as follows
		# > to scale the image down if its height or width exceed the target
		# < will scale the image up if its height and width are smaller than the target
		# ! will scale to fit breaking aspect ratio
		geo_str = size
		case scale
		when 'down'
			# Scale the image down if needed
			geo_str << '\>'
		when 'fit'
			# Scale the image to fit maintaining aspect ratio
			# Nothing to do
		when 'up'
			# Only scale the image up if needed
			geo_str << '\<'
		when 'stretch'
			# Stretch the image to fill the entire slide disregarding aspect ratio
			geo_str << '!'
		end
	
		# Generate the full sized image to a tempfile
		tmp_file = Tempfile.new('isk-image')
		command = "convert #{self.original_filename} -resize #{geo_str}"
		command << " -background #{bg_color.shellescape} -gravity center -extent #{size} png:#{tmp_file.path}"
		if system command
			return compare_new_image(tmp_file)
		else
			tmp_file.unlink
			raise Slide::ImageError, 'Error generating full size slide image!'
		end
	end
	
end