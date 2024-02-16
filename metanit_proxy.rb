require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'net/http'

PROXY_ADDR = '172.67.70.6'
PROXY_PORT = 80  # e.g., 8080
PROXY_USER = 'your_proxy_user'
PROXY_PASS = 'your_proxy_password'

def download_file(url, image_path)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port, PROXY_ADDR, PROXY_PORT, PROXY_USER, PROXY_PASS)
  http.use_ssl = uri.scheme == 'https'
  
  request = Net::HTTP::Get.new(uri.request_uri)
  # Headers are skipped for brevity; re-add them as needed
  response = http.request(request)
  
  open(image_path, 'wb') do |file|
    file.write(response.body)
  end
rescue OpenURI::HTTPError, StandardError => e
  puts "An error occurred while downloading the image: #{e.message}"
end

def scrape_and_convert(url)
  begin
    puts "Scraping URL: #{url}"

    # Use proxy with open-uri
    proxy_uri = URI.parse("http://#{PROXY_ADDR}:#{PROXY_PORT}")
    html_content = URI.open(url, proxy: proxy_uri, http_basic_authentication: [PROXY_USER, PROXY_PASS]).read
    page = Nokogiri::HTML(html_content)

    page.css('li > p > a').each do |link|
      article_url = $site + link['href']
      article_title = link.text.strip
      article_name = article_url.split('/').last

      html_article_content = URI.open(article_url).read
      article_page = Nokogiri::HTML(html_article_content)
      article_page_clear = article_page.css('.innercontainer')

      puts "Scraping URL: #{article_url}"

      markdown_content = generate_markdown(article_page_clear)
      
      File.open("articles/#{article_name}.md", 'w') { |file| file.write(markdown_content) }
      
      article_page_clear.css('img').each do |img|
        img_url = $site + img['src']
        image_name = img_url.split('/').last
        image_path = "images/#{image_name}"
        download_file(img_url, image_path)
      end

      puts "Article '#{article_title}' has been scraped and converted to Markdown."
    end
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
  end
end

def generate_markdown(article_page)
  content = ""
  
  article_page.css('p, h1, h2, div.container, img').each do |element|
    
    if element.name == 'p'
      content += "#{element.text.strip}\n"
    elsif element.name == 'h1'
      content += "# #{element.text.strip}\n\n"
    elsif element.name == 'h2'
      content += "## #{element.text.strip}\n\n"
    elsif element.name == 'div' && element['class'].include?('container')
      puts "Processing: #{element.name} #{element['class']}"
      content += "```\n"
      element.css('div.line').each do |line_code|
        content += "#{line_code.text.strip}\n"
      end
      content += "```\n\n"
    elsif element.name == 'img'
      img_url = $site + element['src']
      image_name = img_url.split('/').last
      content += "![#{image_name}](../images/#{image_name})\n\n"
    end
  end
  
  return content
end

$site = 'https://metanit.com/c/tutorial/'
url = $site + ''

scrape_and_convert(url)