require 'spec_helper'

describe PostItem do
  describe "associations" do
    it "belongs_to canvas_item" do
      subject.should respond_to :canvas_item
    end
    it "belongs_to blog_posts" do
      subject.should respond_to :blog_post
    end
  end

  describe "validations" do
    before do
      blog_post = Factory(:blog_post)
      @post_item = Factory.build(:post_item, :blog_post => blog_post)
    end
    it "is valid" do
      @post_item.should be_valid
    end

    it "is not valid if associated blog post is not valid" do
      @post_item.blog_post.subject = nil
      @post_item.should_not be_valid
    end

    it "is not valid if associated box is not valid" do
      @post_item.canvas_item.box_id = nil
      @post_item.should_not be_valid
    end
  end
end
