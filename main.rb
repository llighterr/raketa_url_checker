require 'net/http'
require 'csv'

def prepare_url(url_string)
  return url_string if url_string.start_with?('http')

  'http://' + url_string
end

def url_exist?(url_string)
  url = URI.parse(prepare_url(url_string))
  req = Net::HTTP.new(url.host, url.port)
  req.use_ssl = (url.scheme == 'https')
  path = url.path if url.path.to_s != ''
  res = req.request_head(path || '/')
  if res.kind_of?(Net::HTTPRedirection)
    url_exist?(res['location']) # Go after any redirect and make sure you can access the redirected URL
  else
    !%W(4 5).include?(res.code[0]) # Not from 4xx or 5xx families
  end
rescue Errno::ENOENT, SocketError
  false #false if can't find the server
end

def check_urls_from_file(path)
  CSV.read(path, headers: true).map do |row|
    status = url_exist?(row['URL'])
    next yield(row['URL'], status) if block_given?

    status
  end
end

if $0 == __FILE__
  check_urls_from_file('websites_to_check.csv') do |url, status|
    puts "#{url} #{status ? 'exists' : "doesn't exist"}"
  end

  p check_urls_from_file('websites_to_check.csv')
end
