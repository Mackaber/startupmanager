require 'spec_helper'

describe Ckeditor::PicturesController do
  before do
    user = Factory(:confirmed_user)
    sign_in user
    @image = fixture_file_upload('/files/SarahAllen.jpg', 'image/jpeg')
  end

  it "populates the 'associated_file_ids' with the id of the newly created picture" do
    session[:associated_file_ids] = []
    post :create, :upload => @image, :CKEditor => 'ckeditor_field' # (this string is kind of arbitrary)
    session[:associated_file_ids].should == [Ckeditor::Picture.last.id]
  end
end
