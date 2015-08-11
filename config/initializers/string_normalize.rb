class String
  def normalize(options = {})
    s = self.downcase
    s = s.gsub(/[\'\"]+/,'')      # embedded quotes
    s = s.gsub(/\s+(a|an|the|and)\s+/, ' ')        # stop words
    s = s.gsub(/^(a|an|the|and)\s+/, ' ')        # stop words
    s = s.gsub(/\s+/,'') if (options[:compare] || options[:collapse_whitespace])
    regex = (options[:compare] ? /[^a-z0-9]+/ : /[^a-z0-9-]+/)
    s = s.gsub(regex, ((options[:compare] || options[:collapse_special]) ? '' : '-'))
    s = s.gsub(/(.)\1+/, '\1') if (options[:collapse_repeating])
    s = s.sub(/-$/,'')
    return s
  end
end