# encoding: utf-8
require 'notified_task'

namespace :lll do
  
  NotifiedTask.new :export_projects => :environment do
    ids = [4472, 4470, 4477, 4465, 4461, 4466, 4459, 4467, 4476, 4478, 4471]    
    projects = ids.collect{|x| Project.find_by_id(x)}.compact
    
    hash = Hash.new{|h,k| h[k] = []}
    
    projects.each do |project|
      hash[project.class.name.tableize] << project.export
      project.members.each do |member|
        hash[member.class.name.tableize] << member.export
      end
      project.canvas_items.find_each do |canvas_item|
        hash[canvas_item.class.name.tableize] << canvas_item.export
      end
      project.blog_posts.each do |blog_post|
        hash[blog_post.class.name.tableize] << blog_post.export
        
        blog_post.comments.each do |x|
          hash[x.class.name.tableize] << x.export
        end        
      end
      (project.hypotheses.where("hypothesis_id IS NULL") + project.hypotheses.where("hypothesis_id IS NOT NULL")).each do |hypothesis|
        hash[hypothesis.class.name.tableize] << hypothesis.export
        
        hypothesis.comments.each do |x|
          hash[x.class.name.tableize] << x.export
        end        

        hypothesis.experiments.each do |x|
          hash[x.class.name.tableize] << x.export
        end
        hypothesis.questions.each do |x|
          hash[x.class.name.tableize] << x.export
        end
        hypothesis.tasks.each do |x|
          hash[x.class.name.tableize] << x.export
        end
      end
    end
    
    File.open(ENV["FILENAME"], "w") {|f| f.write(YAML::dump(hash))}
  end

  NotifiedTask.new :export_after_date => :environment do
    date = ::ActiveSupport::TimeZone.new("UTC").parse(ENV["DATE"])
    hash = {}
    
    [User, Project, Member, CanvasItem, BlogPost, Ckeditor::Asset, Comment].each do |k|
      hash[k.name.tableize] = []
      k.where(["created_at > ?", date]).find_each do |obj|
        hash[k.name.tableize] << obj.export
      end
    end
        
    File.open(ENV["FILENAME"], "w") {|f| f.write(YAML::dump(hash))}
  end
  
  NotifiedTask.new :import => :environment do
    
    users = {}
    projects = {}
    members = {}
    canvas_items = {}
    blog_posts = {}
    hypotheses = {}
    experiments = {}
    questions = {}
    project_tasks = {}
    ckeditor_assets = {}
    comments = {}
    
    begin
      original_delivery_method = ActionMailer::Base.delivery_method
      ActionMailer::Base.delivery_method = :test
    
      ActiveRecord::Base.transaction do
        hash = YAML::load(File.read(ENV["FILENAME"]))
        
        ["users", "projects", "members", "blog_posts", "hypotheses", "experiments", "questions", "project_tasks", "comments",  "canvas_items"].each do |t|
          (hash[t] || []).each do |h|
            r = t.classify.constantize.import(h)
            r.save(:validate => false) if r.new_record? && t.classify.constantize.find_by_id(r.id).nil?
          end
        end

        # hash["users"].each do |user_hash|
        #   user = User.import(user_hash)
        #   user.save! if user.new_record?
        #   # puts "imported user #{user.to_param}"
        #   # users[user_hash["id"]] = user
        # end
        # 
        # hash["projects"].each do |project_hash|
        #   project = Project.import(project_hash)
        #   project.save! if project.new_record?
        #   # puts "imported project #{project.to_param}"
        #   # projects[project_hash["id"]] = project
        # end
        # 
        # hash["members"].each do |member_hash|
        #   # user = users[member_hash["relationships"]["user_id"]]
        #   # user ||= User.find(member_hash["relationships"]["user_id"])
        #   #       
        #   # project = projects[member_hash["relationships"]["project_id"]]
        #   # project ||= Project.find(member_hash["relationships"]["project_id"])
        #       
        #   member = Member.import(member_hash)
        #   member.save! if member.new_record?
        #   # puts "imported member #{member.to_param}"        
        #   # members[member_hash["id"]] = member
        # end
        # 
        # hash["canvas_items"].each do |canvas_item_hash|
        #   # box = Box.find(canvas_item_hash["relationships"]["box_id"])
        #   # 
        #   # item_status = ItemStatus.find(canvas_item_hash["relationships"]["item_status_id"])
        #   # 
        #   # project = projects[canvas_item_hash["relationships"]["project_id"]]
        #   # project ||= Project.find(canvas_item_hash["relationships"]["project_id"])
        #   # 
        #   # project = projects[canvas_item_hash["relationships"]["project_id"]]
        #   # project ||= Project.find(canvas_item_hash["relationships"]["project_id"])
        #       
        #   canvas_item = CanvasItem.import(canvas_item_hash)
        #   canvas_item.save! if canvas_item.new_record?
        #   # puts "imported canvas_item #{canvas_item.to_param}"        
        #   # canvas_items[canvas_item_hash["id"]] = canvas_item
        # end
        # 
        # hash["blog_posts"].each do |blog_post_hash|
        #   canvas_items = blog_post_hash["relationships"]["canvas_item_ids"].collect do |canvas_item_id|
        #     canvas_item = canvas_items[canvas_item_id]
        #     canvas_item ||= CanvasItem.find(canvas_item_id)
        #     canvas_item
        #   end
        # 
        #   member = members[blog_post_hash["relationships"]["member_id"]]
        #   member ||= Member.find(blog_post_hash["relationships"]["member_id"])
        # 
        #   project = projects[blog_post_hash["relationships"]["project_id"]]
        #   project ||= Project.find(blog_post_hash["relationships"]["project_id"])
        #       
        #   blog_post = BlogPost.import(blog_post_hash, canvas_items, member, project)
        #   blog_post.save! if blog_post.new_record?
        #   puts "imported blog_post #{blog_post.to_param}"        
        #   blog_posts[blog_post_hash["id"]] = blog_post
        # end
        #       
        # hash["ckeditor/assets"].each do |obj_hash|
        #   if (obj_hash["relationships"]["blog_post_id"])
        #     assetable = blog_posts[obj_hash["relationships"]["blog_post_id"]]
        #     assetable ||= BlogPost.find(obj_hash["relationships"]["blog_post_id"])
        #   end
        # 
        #   obj = obj_hash["attributes"]["type"].constantize.import(obj_hash, assetable)
        #   obj.save! if obj.new_record?
        #   puts "imported asset #{obj.to_param}"
        #   ckeditor_assets[obj_hash["id"]] = obj
        # end
        #       
        # hash["comments"].each do |obj_hash|
        #   blog_post = blog_posts[obj_hash["relationships"]["blog_post_id"]]
        #   blog_post ||= BlogPost.find(obj_hash["relationships"]["blog_post_id"])
        # 
        #   member = members[obj_hash["relationships"]["member_id"]]
        #   member ||= Member.find(obj_hash["relationships"]["member_id"])
        #       
        #   obj = Comment.import(obj_hash, blog_post, member)
        #   obj.save! if obj.new_record?
        #   puts "imported comment #{obj.to_param}"        
        #   comments[obj_hash["id"]] = obj
        # end
      
      end
      
      puts ActionMailer::Base.deliveries.last.inspect
      
    ensure
      ActionMailer::Base.delivery_method = original_delivery_method
    end
  end
  
end

  