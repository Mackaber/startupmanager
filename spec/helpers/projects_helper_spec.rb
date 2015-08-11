require "spec_helper"

describe ProjectsHelper do

  before do
    owner = Factory(:owner)
    @project = owner.project
  end

  describe "canvas_items_for_box" do
    before do
      @box = Box.first
      @tomorrow = Date.tomorrow + 1.day
    end

    it "returns the canvas items for the box" do
      canvas_item = Factory(:canvas_item, :project => @project)
      ci2 = canvas_item.create_updated(:text => 'newer')
      assigns[:project] = @project
      helper.canvas_items_for_box(@box, @tomorrow).count.should == 1
      helper.canvas_items_for_box(@box, @tomorrow).first.should == ci2
    end

    it "only shows records that have not been deleted -- i.e. are not deleted" do
      canvas_item = Factory(:canvas_item, :project => @project)
      deleted_canvas_item = Factory(:canvas_item, :project => @project)
      deleted_canvas_item.create_updated(:deleted => true)
      assigns[:project] = @project
      helper.canvas_items_for_box(@box, @tomorrow).count.should == 1
      helper.canvas_items_for_box(@box, @tomorrow).first.should == canvas_item
    end

    it "orders canvas items by creation time" do
      dates = 5.times.map { |i| Date.tomorrow - i.days }
      dates.each { |d| Factory(:canvas_item, :created_at => d, :project => @project, :box => Box.first) }
      helper.canvas_items_for_box(@box, @tomorrow).map { |c| c.created_at.to_date }.should == dates.reverse
    end
  end

  describe "generate_thumbnails" do
    before do
      #f = File.open('blog_post_body.txt', 'r')
      #@post = Factory(:blog_post, :member => @owner, :body => f.read)
      #f.close
    end

    it "returns no images if post has no images" do
      helper.generate_thumbnails(Factory(:blog_post)).should be_empty
    end

    it "returns an image if post has one" do
      post = Factory(:blog_post, :body => 'Look what we saw <img src="giant-prawn.jpg" />')
      helper.generate_thumbnails(post).split('</img>').count.should == 1
    end

    it "only produces images for the first 3 images found" do
      post = Factory(:blog_post, :body => 'Look <img src="a.jpg"/><img src="b.jpg"/><img src="c.jpg"/><img src="d.jpg"/>')
      helper.generate_thumbnails(post).scan(/<img.+?\/>/).count.should == 3
    end

    it "gives the image frame a class of 'large-thumb' if only one to display" do
      post = Factory(:blog_post, :body => 'Look <img src="a.jpg"/>')
      helper.generate_thumbnails(post).scan(/<div.+?<\/div>/).first.should =~ /large-thumb/
    end

    it "gives both image frames a class of 'medium-thumb' if two images to display" do
      post = Factory(:blog_post, :body => 'Look <img src="a.jpg"/><img src="a.jpg"/>')
      helper.generate_thumbnails(post).scan(/<div.+?<\/div>/).first.should =~ /medium-thumb/
      helper.generate_thumbnails(post).scan(/<div.+?<\/div>/)[1].should =~ /medium-thumb/
    end

    it "gives the 1st images a class of 'large-thumb' and the other images a class of 'small-thumb' if 3 images to display" do
      post = Factory(:blog_post, :body => 'Look <img src="a.jpg"/><img src="a.jpg"/><img src="a.jpg"/>')
      helper.generate_thumbnails(post).scan(/<div.+?<\/div>/).first.should =~ /large-thumb/
      helper.generate_thumbnails(post).scan(/<div.+?<\/div>/)[1].should =~ /small-thumb/
      helper.generate_thumbnails(post).scan(/<div.+?<\/div>/)[2].should =~ /small-thumb/
    end

  end
end
