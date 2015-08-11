require "spec_helper"

describe Jobs::BlogDigest do

  describe "mail_digests" do

    describe "without new posts" do
      it "does not send mail" do
        BlogPostMailer.should_not_receive(:mail_digest)
        Jobs::BlogDigest.perform
      end
    end

    describe "with new posts" do
      before do
        3.times { Factory(:owner) } #other users
        @owner = Factory(:owner)
        3.times { Factory(:owner) } #more other users
        @project = @owner.project
        member = Factory(:member_who_has_joined_project, :project => @owner.project, :role_name => 'Contributor')
        Factory(:blog_post, :member => member, :project => @project)
        @message = double
      end

      it "does not send mail to users who have not set digest_mail to true" do
        @owner.user.setting.update_attribute(:digest_email, false)
        BlogPostMailer.should_not_receive(:mail_digest)
        @message.should_not_receive(:deliver)
        Jobs::BlogDigest.perform
      end

      describe "user has opted for digest mail" do
        before do
          @owner.user.setting.update_attributes({:post_email => false, :feedback_email => false, :digest_email => true})
          @message.should_receive(:deliver)
        end

        it "sends digest mail to users when there is a new post" do
          BlogPostMailer.should_receive(:mail_digest).once.and_return(@message)
          Jobs::BlogDigest.perform
        end

        it "the correct user gets the email, with the correct project" do
          subject = "#{@owner.user.name}, Team #{@owner.project.name}"
          BlogPostMailer.should_receive(:mail_digest).with(@owner.user, [@project]).and_return(@message)
          Jobs::BlogDigest.perform
        end
      end
    end
  end

end
