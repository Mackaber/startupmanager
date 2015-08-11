require 'spec_helper'

describe CanvasItem do
  describe "associations" do
    it "belongs to a project" do
      subject.should respond_to(:project)
    end
    it "has a box" do
      subject.should respond_to :box
    end
    it "has a item_status" do
      subject.should respond_to :item_status
    end
    it "has_many post_items" do
      subject.should respond_to :post_items
    end
    it "has_many blog_posts" do
      subject.should respond_to :blog_posts
    end
  end

  describe "validations" do
    before do
      @c_item = CanvasItem.new(Factory.attributes_for(:canvas_item))
    end
    it "is valid" do
      @c_item.should be_valid
    end
    [:project_id, :box_id, :item_status_id, :text].each do |att|
      it "is not valid without #{att}" do
        @c_item[att] = nil
        @c_item.should_not be_valid
      end
    end

    it 'is not valid with empty text' do
      @c_item.text = ''
      @c_item.should_not be_valid
    end
  end

  describe "text length" do
    it "truncates text strings over 140 characters" do
      canvas_item = Factory(:canvas_item, :text => "a"*150)
      canvas_item.text.length.should == 140
    end
  end

  describe 'create_updated' do
    it 'should create a copy of the canvas item' do
      ci = Factory(:canvas_item)
      ci2 = ci.create_updated
      ci2.box.should == ci.box
      ci2.project.should == ci.project
      ci2.text.should == ci.text
      ci2.item_status.should == ci.item_status
      ci2.original_id.should == ci.original_id
      ci2.should_not be_new_record
      ci2.id.should_not == ci.id
    end

    it "changes attributes" do
      ci = Factory(:canvas_item)
      ci2 = ci.create_updated(:text => 'new text', :item_status_id => ItemStatus[:valid])
      ci2.reload
      ci2.text.should == 'new text'
      ci2.item_status_id.should == ItemStatus[:valid]
    end

    it 'does not change attributes of original' do
      # TODO: there is some intermittent failure condition here -- this test fails a few percent of the time
      ci = Factory(:canvas_item)
      orig_attrs = ci.attributes
      orig_attrs.delete("inactive_at")
      ci2 = ci.create_updated(:text => 'new text', :item_status_id => ItemStatus[:valid])
      ci.reload
      attrs = ci.attributes
      attrs.delete("inactive_at")
      pending "this should work but doesn't ?!" do  # FIXME
        attrs.should eql(orig_attrs)
      end
    end
  end

  describe "original_id" do
    it "gets the value of the id if it is a totally new canvas item" do
      ci = Factory(:canvas_item)
      ci.original_id.should == ci.id
    end
  end

end
