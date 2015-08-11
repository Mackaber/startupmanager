Factory.define :project do |f|
  f.sequence(:name) { |n| "proj-#{Time.now.to_i}-#{n}" }
  f.url "http://www.google.com/"
  f.pitch "Use our product and ensure your health, wealth and happiness"
end

Factory.define :user do |f|
  f.name { Faker::Name.name.sub(' ', " Alien ") }
  f.sequence(:email) { |n| "user#{Time.now.to_i}-#{n}@example.com" }
  f.password 'password'
  f.password_confirmation 'password'
end

Factory.define :confirmed_user, :parent => :user do |f|
  f.after_create do |u|
    # u.confirm!
  end
end

Factory.define :member do |f|
  f.user { Factory(:user) }
  f.level 'Viewer'
  f.role_name "Other"

  #reload project so the members collection will be populated
  #TODO: can we fix this?
  f.after_create do |m|
    m.project.reload unless m.project.nil?
  end
end

Factory.define :member_with_confirmed_user, :parent => :member do |f|
  f.user { Factory(:confirmed_user) }
end

Factory.define :member_who_has_joined_project, :parent => :member_with_confirmed_user do |f|
  f.after_create do |m|
    m.update_attribute('join_code', nil)
  end
end

Factory.define :hypothesis do |f|
  f.project_id {Factory(:project).id}
  f.created_by_member_id { Factory(:member_who_has_joined_project, :project_id => Project.last.id).id}
  f.title {Faker::Company.catch_phrase}
  f.sequence(:position) {|n| n}
end

Factory.define :owner, :parent => :member_with_confirmed_user do |f|
  f.project { Factory(:project) }
  f.level 'Admin'
  f.is_owner true
end

Factory.define :lll_owner, :parent => :owner do |f|
  f.project { Factory(:project, :name => "LeanLaunchLab", :created_at => Time.parse("2011-08-07 23:50:00 UTC")) }
  f.after_create do |m|
    m.user.update_attributes(:name => "Ben Mappen", :email => "ben@leanlaunchlab.com")
  end
end

Factory.define :canvas_item do |c|
  c.box { Box.first }
  c.project { Factory(:project) }
  c.sequence(:text) { |n| "some item #{n}" }
  c.item_status { ItemStatus.first }
end

Factory.define :blog_post do |f|
  f.member { Factory(:owner) }
  f.sequence(:subject) { |n| "subject #{n}" }
  f.sequence(:body) { |n| "body #{n}" }
  f.project nil
  f.published_at Time.now
  f.the_ask "Just FYI"

  f.after_build do |b|
    b.project = b.member.project if b.project.nil?
  end
end

Factory.define :comment do |f|
  f.blog_post nil
  f.member nil
  f.sequence(:body) { |n| "body #{n}" }

  f.after_build do |c|
    if c.blog_post.nil? && c.member.nil?
      c.blog_post = Factory(:blog_post)
      c.member = c.blog_post.member
    elsif c.blog_post.nil?
      c.blog_post = Factory(:blog_post, :member => c.member)
    elsif c.member.nil?
      c.member = c.blog_post.member
    end
  end
end

Factory.define :learning do |f|
  f.blog_post { Factory(:blog_post) }
  f.sequence(:content) { |n| "content #{n}" }
  f.after_create do |l|
    l.blog_post.reload
  end
end

Factory.define :post_item do |p|
  p.canvas_item { Factory(:canvas_item) }
  p.blog_post nil

  p.after_create do |c|
    c.blog_post = Factory(:blog_post, :project => c.canvas_item.project)
  end

end

Factory.define :picture, :class => Ckeditor::Picture do |f|
  f.sequence(:data_file_name) { |n| "file_#{n}.jpg" }
  f.data_content_type "image/jpeg"
  f.data_file_size 1024
  f.type "Ckeditor::Picture"
end

Factory.define :user_activity do |f|
  f.user { Factory(:user) }
  f.action "Feedback"
  f.description { Faker::Company.bs + " and " + Faker::Company.bs + " then " + Faker::Company.bs }

  f.after_build do |b|
    b.name = b.user.name
    b.email = b.user.email
    b.save!
  end
end
