class Ckeditor::Picture < Ckeditor::Asset
  # TODO: this S3 info should probably be moved out of here.  See http://devcenter.heroku.com/articles/config-vars
  has_attached_file :data,
                    :storage => :s3,
                    :s3_protocol => "https",
                    :bucket => AWS_S3_BUCKET,
                    :s3_credentials => {
                        :access_key_id => AWS_ACCESS_KEY_ID,
                        :secret_access_key => AWS_SECRET_ACCESS_KEY
                    },
                    :s3_permissions => :public_read,
                    :styles => {:content => '800>', :thumb => '118x100#'}

  validates_attachment_size :data, :less_than => 10.megabytes
  validates_attachment_presence :data

  def to_s
    self.data_file_name
  end
  
  def url_content
    url(:content)
  end
end
