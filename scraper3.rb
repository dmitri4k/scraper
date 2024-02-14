require 'nokogiri'
require 'open-uri'
require 'down'
require 'fileutils'

# Function to sanitize file names
def sanitize_file_name(name)
  name.downcase.gsub(/[^0-9a-z.\-]/, '_')
end

# Function to scrape articles from a given URL
def scrape_articles(url)
  # Print the URL before opening it
  puts "Scraping URL: #{url}"
  begin
    doc = Nokogiri::HTML(URI.open(url))
  rescue OpenURI::HTTPError => e
    puts "Error: #{e.message}"
    return
  end

  # Find and loop through article elements
  doc.css('#content').each do |article|
    article_title = article.at_css('h1').text
    article_content = article.css('.clear').text
    code_examples = article.css('.notranslate').map(&:text)
    images = article.css('img').map { |img| img['src'] }

    # Get the HTML file name from the URL
    html_file_name = url.split('/').last.gsub('.html','')

    # Sanitize the HTML file name for use as a markdown file name
    sanitized_filename = sanitize_file_name(html_file_name)

    # Write content to markdown file
    FileUtils.mkdir_p('articles')
    File.open("articles/#{sanitized_filename}.md", 'w') do |file|
      file.puts "# #{article_title}"
      file.puts "\n#{article_content}"

      code_examples.each do |example|
        file.puts "```ruby\n#{example}\n```"
      end

      images.each do |img_url|
        file.puts "![Image](#{img_url})"
        Down.download(img_url, destination: "images")
      rescue StandardError => e
        puts "Error downloading image: #{e.message}"
      end
    end
  end

  # Find and follow links to other relevant pages
  doc.css('a').map { |link| link['href'] }.each do |link|
    # Check if the link is relevant to the articles you want to scrape
    if link.include?('c/') # Assuming 'c/' is part of the relevant article links
      scrape_articles(URI.join(url, link).to_s)
    end
  end
end

# Start scraping from the main URL
scrape_articles('https://learnc.info/c/')