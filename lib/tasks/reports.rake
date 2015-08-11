desc "Generate admin reports"
task :reports => :environment do

  Reports::MembershipReport.create!
  Reports::BlogPostsReport.create!
end