#encoding: utf-8
class Jobs::AttachmentUpload < Jobs::Job
    
  def self.run(member_id, item_type, item_id, file_data, file_original_filename, file_content_type) 
    if ((member = Member.find_by_id(member_id)) && (item = item_type.constantize.find_by_id(item_id)))
      Audit.as_user(member.user) do
        o = StringIO.new(Base64.decode64(file_data))
        o.instance_variable_set(:@original_filename, file_original_filename)
        def o.original_filename; @original_filename; end
        o.instance_variable_set(:@content_type, file_content_type)
        def o.content_type; @content_type; end
    
        attachment = item.attachments.build(:member => member, :data => o)
        Attachment.transaction do
          item.project.lock!
          attachment.save!
        end
      end
    end
  end
  
end