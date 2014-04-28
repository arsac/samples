class ImageUploader < CarrierWave::Uploader::Base
  
  include CarrierWave::Uploader::Callbacks
  include CarrierWave::RMagick
  include CarrierWave::MimeTypes

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper
  
  process :dynamic_resize_to_fit => :default
  process :set_content_type
  
  
  # Choose what kind of storage to use for this uploader:
  storage :file

  after :remove, :remove_empty_store_dir
  
  def store_dir
    "#{base_store_dir}/#{first_level_store_dir}/#{model.id}"
  end
  
  def base_store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}"
  end
  
  #Get past folder limitations
  def first_level_store_dir
  	"#{(model.id.to_f / 31999).ceil}"
  end
  
  def remove_empty_store_dir
  	path = ::File.expand_path(store_dir, root)
  	Dir.delete(path)
  	
  	path = ::File.expand_path("#{base_store_dir}/#{first_level_store_dir}", root)
  	Dir.delete(path)
  	
  	path = ::File.expand_path(base_store_dir, root)
  	Dir.delete(path)
  	
  	rescue SystemCallError
    	true
  end
  
      
  DEFAULT_VERSIONS = {
  	:tiny => { 
  		:resize_to_fill => [50,50],
	  	:convert => 'png'
	},  		
  	:thumb => { 
  		:resize_to_fill => [200,200],
	  	:convert => 'png'
	},
	:medium => { 
  		:resize_to_fit => [320,220],
	  	:convert => 'png'
	},
	:pdf => { 
  		:resize_to_limit => [320,220],
	  	:convert => 'jpg',
	  	:quality => 84
	},
	:large => { 
  		:resize_to_fit => [700,500],
	  	:convert => 'jpg',
	  	:quality => 84
	}
  }
  
  DEFAULT_VERSIONS.each do |v, val|
  	version v do
  		attr_accessor :v
  		val.each do |k,p|
  			process k => p
  		end
  	end
  end
  
  AssetSize.all.each do |asset_size|
  	  
      version asset_size.version, :if => :is_lazy? do
        attr_accessor :asset_size
      	process :quality => 80
      	process :process_dynamic_asset
      	
      	define_method(:asset_size) { asset_size }
      end
  end unless !AssetSize.table_exists?

  
  
  def is_lazy?(file)
  	!model.new_record? || !model.source_changed?
  end
  
  def process_dynamic_asset
  	send(asset_size.process,*asset_size.dimensions) do |img|
  		
  		unless asset_size.watermark.nil?
    		logo = Magick::Image.read(asset_size.watermark).first
			  img = img.composite(logo, Magick::SouthEastGravity, 15, 0, Magick::OverCompositeOp)
		  end
		img
	  end if respond_to?(asset_size.process)
  end
  
  def dynamic_resize_to_fit(size)
  	asset_size = AssetSize.find_by_key(size)

    resize_to_fit *(asset_size.dimensions) unless asset_size.nil?
  end
  
  #process :store_geometry
  def geometry
    @geometry ||= get_geometry
  end
  
  def get_geometry
    if @file
      img = ::Magick::Image::read(@file.file).first
      geometry = { width: img.columns, height: img.rows }
    end
  end
  
  
  def retrieve_version(version)
  	versions[version.to_sym] unless versions[version.to_sym].nil?
  end
  
  def retrieve_model_version(version)
  	model.version(version)
  end
  
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
     %w(jpg jpeg gif png)
  end
  
  #Added a safe_version which will process the version if it doesn't exist before returning the object
  def safe_version(version_name)
  	  _version = send(version_name) if respond_to?(version_name)
  	  
	  unless _version.nil? || File.exist?(_version.path)
	  	recreate_versions!(version_name)
	  end
	  _version
  end
  
  def self.version_dimensions(version)
  	DEFAULT_VERSIONS[version]
  end
  
  def url(options = {})
  	
  	if options && versions[options].nil? && options.is_a?(Symbol)
  		safe_version options
  	end
  	
  	super(options)
  	
  end
  
end
