#encoding: utf-8
class OrganizationMailer < ActionMailer::Base
  
  include ActionView::Helpers::TextHelper

  def new_charge(charge)
    @charge = charge
    @time = Time.now.in_time_zone(charge.organization.cc_user.setting.time_zone)
    mail(:to => charge.organization.cc_user.email,
      :subject => "Recibo de pago de Spartans Academy"
    )
  end
    
  def member_receipt(organization_member)
    @time = Time.now.in_time_zone(organization_member.user.setting.time_zone)
    @organization_member = organization_member
    mail(:to => organization_member.user.email,
      :subject => "Recibo de pago de Spartans Academy"
    )
  end
  
  def trial_promo(organization_member)
    @organization = organization_member.organization
    @user = organization_member.user
    @recommended = SubscriptionLevel.recommended(organization_member.organization)
    mail(
      :to => organization_member.user.email,
      :subject => "Trial ending in #{(@organization.trial_end_date - Date.today + 1).to_i} days. #{@organization.promotion.monthly_discount_percent}% off if you upgrade within 24 hours"
    )
  end
  
  def trial_warn(organization_member)
    @organization = organization_member.organization
    @user = organization_member.user
    mail(
      :to => organization_member.user.email,
      :subject => "Trial ending in #{pluralize((@organization.trial_end_date - Date.today + 1).to_i, "day")}"
    )
  end
  
end
