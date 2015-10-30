#encoding: utf-8
class ProjectMailer < ActionMailer::Base
  
  def goal_invite(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Tu siguiente paso: Invita a tu Equipo"
    )
  end
  
  def goal_interview(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Tu siguiente paso: Sube una Entrevista con un Cliente"
    )
  end
  
  def goal_validate(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Tu siguiente paso: Valida una Hipotesis"
    )
  end
  
  def goal_test(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Tu siguiente pso: Prueba una Hipotesis"
    )
  end
  
  def goal_hypothesis(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Tu siguiente paso: Crea una Hipothesis"
    )
  end
  
  def goal_canvas(member)
    @member = member
    mail(
      :to => member.user.email,
      :subject => "Tu siguiente paso: Llena tu Canvas"
    )
  end 
  
end
