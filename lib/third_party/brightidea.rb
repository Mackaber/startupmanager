# encoding: utf-8
class ThirdParty::Brightidea
  
  def initialize(api_key)
    @api_key = api_key
    @http = HTTPClient.new
    @url = "https://na5.brightidea.com/BIP/API/api.bix"
    @affiliate_id = self.get_affiliate_list
  end
  
  def get_affiliate_list
    doc = self.request("bi.api.getAffiliateList")
    return doc.at_xpath("//AFFILIATE/ID").content
  end
  
  def get_member_list
    doc = self.request("bi.affiliate.getMemberList", {:a => @affiliate_id})
    doc.xpath("//MEMBERS/MEMBER").collect do |member|
      {
        :name => member.at_xpath("SCREEN_NAME").content,
        :email => member.at_xpath("EMAIL").content,
        :id => member.at_xpath("ID").content
      }
    end
  end
  
  def get_idea(idea_id)
    doc = self.request("bi.affiliate.campaign.idea.get", {:i => idea_id})
    {
      :title => doc.at_xpath("IDEA/TITLE").content,
      :description => doc.at_xpath("IDEA/DESCRIPTION").content,
      :member_id => doc.at_xpath("IDEA/MEMBER_ID").content,
      :url => doc.at_xpath("IDEA/URL").content
    }
  end
  
  def request(function, query = nil)
    content = @http.get_content(@url, query, {"API_KEY" => @api_key, "API_FUNCTION" => function})
    doc = Nokogiri::XML(content)
    return doc
  end
  
end