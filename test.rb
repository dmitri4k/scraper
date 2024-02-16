require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'net/http'

url = 'https://metanit.com/c/tutorial/6.5.php'

html_content = URI.open(url).read
Nokogiri::HTML(html_content)
page = Nokogiri::HTML(html_content)
puts "#{page}"