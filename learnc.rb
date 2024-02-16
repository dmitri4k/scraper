require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'net/http'

def download_file(url, image_path)
  headers = {
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Encoding' => 'gzip, deflate, br',
    'Accept-Language' => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7'
  }
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'

  request = Net::HTTP::Get.new(uri.request_uri)
  headers.each { |key, value| request[key] = value }

  response = http.request(request)

  open(image_path, 'wb') do |file|
    file.write(response.body)
  end
rescue OpenURI::HTTPError => e
  puts "An HTTP error occurred while downloading the image: #{e.message}"
rescue StandardError => e
  puts "An error occurred while downloading the image: #{e.message}"
end


def scrape_and_convert(url)
  begin
    puts "Scraping URL: #{url}"

    html_content = URI.open(url).read
    page = Nokogiri::HTML(html_content)

    page.css('li > a').each do |link|
      article_url = $site + link['href']
      article_title = link.text.strip
      article_name = article_url.split('/').last.split('.').first

      html_article_content = URI.open(article_url).read
      article_page = Nokogiri::HTML(html_article_content)
      article_page_clear = article_page.css('.article')

      puts "Scraping URL: #{article_url}"

      markdown_content = generate_markdown(article_page_clear)
      
      File.open("articles/#{article_name}.md", 'w') { |file| file.write(markdown_content) }
      
      article_page_clear.css('img').each do |img|
        img_url = $site + img['src']
        image_name = img_url.split('/').last
        image_path = "images/#{image_name}"
        download_file(img_url, image_path)
      end

      # puts "Article '#{article_title}' has been scraped and converted to Markdown."
    end
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
  end
end

def generate_markdown(article_page)
  content = ""
  
  article_page.css('p, h1, h2, pre, img').each do |element|
    
    if element.name == 'p'
      content += "#{element.text.strip}\n\n"
    elsif element.name == 'h1'
      content += "# #{element.text.strip}\n\n"
    elsif element.name == 'h2'
      content += "## #{element.text.strip}\n\n"
    elsif element.name == 'pre'
      content += "```\n#{element.text.strip}\n```\n\n"
    elsif element.name == 'img'
      img_url = $site + element['src']
      image_name = img_url.split('/').last
      if image_name != 'mail.png'
        content += "![#{image_name}](../images/#{image_name})\n\n"
      end
    end
  end
  
  return content
end

$site = 'https://learnc.info'
url = $site + '/c/'

scrape_and_convert(url)





