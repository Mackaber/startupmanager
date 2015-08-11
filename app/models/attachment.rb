class Attachment < ActiveRecord::Base
  
  belongs_to :item, :polymorphic => true, :touch => true
  belongs_to :member
  has_one :project, :through => :member
  
  validates_presence_of :member, :item
  
  has_attached_file :data,
    :storage => :s3,
    :s3_protocol => (["development", "test"].include?(Rails.env) ? "http" : "https"),
    :s3_credentials => { :access_key_id => AWS_ACCESS_KEY_ID, :secret_access_key => AWS_SECRET_ACCESS_KEY },
    :bucket => AWS_S3_BUCKET,
    :s3_permissions => :private,
    :path => ":class/:attachment/:id/:filename" # :style
  
  validates_attachment_presence :data
  validates_attachment_size :data, :less_than => 50.megabytes
  
  acts_as_audited :associated_with => :project
  
  validate do |attachment|
    if (attachment.new_record? && !attachment.item.project.organization.can_add_attachment?(attachment.data_file_size))
      attachment.errors.add(:base, "Organization #{project.organization} has the maximum amount of attachment storage.")
    end
  end  
  
  # validates_attachment_content_type :data, :message => "Please upload .gif, .jpg, or .png files only", :content_type => %w( image/jpeg image/png image/gif image/pjpeg image/x-png )
  
  def to_hash
    Rails.cache.fetch(self.cache_key + "/hash", :expires_in => 7200) do
      {
        :type => self.class.name.underscore,
        :id => self.id,
        :item_type => self.item_type.underscore,
        :item_id => self.item_id,
        :name => self.data_file_name,
        :size => self.data_file_size,
        :url => self.data.expiring_url(7200),
        :created_at => self.created_at
      }
    end
  end
  
end