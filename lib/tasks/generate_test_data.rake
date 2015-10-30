# encoding: utf-8
# require 'faker'
# 
# namespace :create_test_data do
#   desc 'Create data for testing'
#   task :canvas_history => :environment do
#     project = Project.find_by_name('history')
#     if project
#       CanvasItem.delete_all(:project_id => project.id)
#       project.destroy
#     end
#     user = User.find_by_email('test@leanlaunchlab.com') # uses the default password that's in the :user factory - go look there!
#     user.destroy if user
#     user = Factory(:confirmed_user, :name => 'test', :email => 'test@leanlaunchlab.com')
#     project = Factory(:project, :name => 'history')
#     owner = Factory(:owner, :project => project, :user => user)
#     startDate = Date.today.end_of_week - 10.weeks
#     project.update_attribute(:created_at, startDate)
#     9.times do |n|
#       date = startDate + (n + 1).weeks
#       7.times do
#         add_item date, project, true
#       end
#       5.times do
#         change_text date, project
#         update_status date, project
#       end
#       3.times do
#         delete_item date, project
#       end
#     end
#   end
# 
#   private
# 
#   def add_item date, project, faker = true
#     box = Box.all.sample
#     if faker
#       f = Factory(:canvas_item, :project => project, :box => box, :text => Faker::Company.catch_phrase,
#                   :created_at => date - (rand(7).days))
#     else
#       Factory(:canvas_item, :project => project, :box => box, :text => "#{date.strftime("%a-%b-%d")} box: #{box.name}",
#               :created_at => date - (rand(7).days))
#     end
#   end
# 
#   def change_text date, project
#     item = random_item date, project
#     item.create_updated(:text => item.text + ' EDITED: must ' + Faker::Company.bs).update_attribute(:created_at, date)
#   end
# 
#   def update_status date, project
#     item = random_item date, project
#     item.create_updated(:item_status => ItemStatus.all.sample).update_attribute(:created_at, date)
#   end
# 
#   def delete_item date, project
#     item = random_item date, project
#     item.create_updated(:deleted => true).update_attribute(:created_at, date)
#   end
# 
#   def random_item date, project
#     item = CanvasItem.where(:project_id => project.id).where("created_at <= ? and created_at >= ?", date, date - 7.days).sample
#     item
#   end
# end
# 
