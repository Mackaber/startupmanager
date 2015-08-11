class Api::V1::UpdatesController < Api::V1::V1BaseController
  
  skip_authorization_check
  
  def index    
    if (params.has_key?(:t))
      time = Time.at(params[:t].to_i / 1000)
    else
      time = Time.zone.now
    end
    
    if (params.has_key?(:limit))
      limit = params[:limit].to_i
    else
      limit = 25
    end
    
    project_ids = current_user.live_projects.collect{|x| x.id}
    
    blog_posts = BlogPost.where(["project_id IN (?) AND published_at < ?", project_ids, time]).order("published_at DESC").limit(limit)
    hypotheses = Hypothesis.where(["project_id IN (?) AND completed_at < ?", project_ids, time]).order("completed_at DESC").limit(limit)    
    both = (blog_posts + hypotheses).sort_by{|x| x.respond_to?(:published_at) ? x.published_at : x.completed_at}.reverse.slice(0, limit)
    blog_posts = both.select{|x| x.is_a?(BlogPost)}
    hypotheses = both.select{|x| x.is_a?(Hypothesis)}
    
    comments = both.collect{|x| x.comments}.flatten
    members = (both.collect{|x| x.project.members} + comments.collect{|x| x.member}).flatten.uniq
    
    render(:json => {
      :attachments => both.collect{|x| x.attachments}.flatten.collect{|x| x.to_hash},
      :blog_posts => blog_posts.collect{|x| x.to_hash},
      :comments => comments.collect{|x| x.to_hash},
      :experiments => hypotheses.collect{|x| x.experiments}.flatten.collect{|x| x.to_hash},
      :hypotheses => hypotheses.collect{|x| x.to_hash},
      :members => members.collect{|x| x.to_hash},
      :questions => hypotheses.collect{|x| x.questions}.flatten.collect{|x| x.to_hash},
      :tasks => hypotheses.collect{|x| x.tasks}.flatten.collect{|x| x.to_hash},
      :users => members.collect{|x| x.user.to_hash}
    })        
  end
  
  
end
