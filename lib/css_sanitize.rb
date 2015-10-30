# encoding: utf-8
__END__

# Include this module into your ActiveRecord model.
module CssSanitize

  def custom_css=(text)
    # Mostly stolen from http://code.sixapart.com/svn/CSS-Cleaner/trunk/lib/CSS/Cleaner.pm
    text = "Error: invalid/disallowed characters in CSS" if text =~ /(\w\/\/)/ # a// comment immediately following a letter
    text = "Error: invalid/disallowed characters in CSS" if text =~ /(\w\/\/*\*)/ # a/* comment immediately following a letter
    text = "Error: invalid/disallowed characters in CSS" if text =~ /(\/\*\/)/ # /*/ --> hack attempt, IMO

    # Now, strip out any comments, and do some parsing.
    no_comments = text.gsub(/(\/\*.*?\*\/)/, "") # filter out any /* ... */
    no_comments.gsub!("\n", "")
    # No backslashes allowed
    evil = [
        /(\bdata:\b|eval|cookie|\bwindow\b|\bparent\b|\bthis\b)/i, # suspicious javascript-type words
        /behaviou?r|expression|moz-binding|@import|@charset|(java|vb)?script|[\<]|\\\w/i,
        /[\<>]/, # back slash, html tags,
        /[\x7f-\xff]/, # high bytes -- suspect
        /[\x00-\x08\x0B\x0C\x0E-\x1F]/, #low bytes -- suspect
        /&\#/, # bad charset
    ]
    evil.each { |regex| text = "Error: invalid/disallowed characters in CSS" and break if no_comments =~ regex }

    write_attribute :custom_css, text
  end
end


__END__

TODO: this file isn't actually used in the system.  Either use it or get rid of it

For more info on this file see
"Address XSS vulnerability for blog posts" - https://www.pivotaltracker.com/story/show/17819769
http://devblog.supportbee.com/2011/08/15/sanitizing-css-in-rails
http://stackoverflow.com/questions/2985600/how-good-is-the-rails-sanitize-method
http://stackoverflow.com/questions/3051285/sanitizing-css-in-rails
https://github.com/courtenay/css_file_sanitize

__________________________

Add this into blog_post.rb:

  def body=(string)
    # note: this doesn't work because CssSanitize expects CSS, not HTML.  Need to parse out each style attribute and pass them individually.
    # not sure how to do this parsing.  nokogiri?  a full parser that could crash heroku sounds like a pain in the ass
    self.custom_css = string
    write_attribute :body, self.custom_css
  end

__________________________

Add this into blog_post_spec.rb:

  describe "sanitizing CSS" do
    it "allows legitimate CSS styles through" do
      honorable_body = %Q[<p style="background-color:#EEEEEE;">I'm just having good clean fun</p>]
      blog_post = Factory(:blog_post, :body => honorable_body)
      blog_post.body.should == honorable_body
    end

    it "thwarts tricky javascript-in-CSS attacks" do
      evil_body = %Q[<p style="background-image: url('javascript:alert');">XSS Attack here</p>]
      blog_post = Factory(:blog_post, :body => evil_body)
      repentant_body = "Error: invalid/disallowed characters in CSS"
      blog_post.body.should == repentant_body
    end
  end

