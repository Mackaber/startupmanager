require "csv"

class Admin::SignupsController < Admin::AdminController
  
  def index
    @signups = Signup.order("created_at desc")
    respond_to do |format|
      format.html {}
      format.csv do
        out = CSV.generate do |csv|
          csv << [
            "Signup ID",
            "Email",
            "Date"
          ]
          @signups.each do |signup|
            csv << [signup.id, signup.email, signup.created_at.strftime("%m/%d/%y %I:%m %p")]
          end
        end
        send_data out, :type => "text/csv", :filename => "signups-#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv"
      end  
    end    
  end
  
end