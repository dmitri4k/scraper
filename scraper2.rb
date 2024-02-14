require 'nokogiri'
require 'open-uri'
require 'kramdown'
require 'down'

# Function to convert content to markdown format using Kramdown
def to_markdown(title, content, code_examples, images)
  markdown_content = "# #{title}\n\n"
  markdown_content += "#{content}\n\n"

  code_examples.each do |example|
    markdown_content += "```\n#{example}\n```\n\n"
  end

  images.each do |img_url|
    markdown_content += "![Image](#{img_url})\n\n"
  end

  markdown_content
end

# Function to scrape articles from a given URL and convert to markdown
def scrape_and_convert_articles(url)
  doc = Nokogiri::HTML(URI.open(url))

  # Find and loop through article elements
  doc.css('YOUR_ARTICLE_SELECTOR_HERE').each do |article|
    article_title = article.at_css('h1').text
    article_content = article.at_css('clear').text
    code_examples = article.css('notranslate').map(&:text)
    images = article.css('img').map { |img| img['src'] }

    # Add debug output
    puts "Article Title: #{article_title}"
    puts "Article Content: #{article_content}"
    puts "Code Examples: #{code_examples}"
    puts "Images: #{images}"

    # Convert article content to markdown using Kramdown
    markdown_content = to_markdown(article_title, article_content, code_examples, images)

    # Print the markdown content to console
    puts markdown_content

    # Write content to a markdown file
    File.open("#{article_title.downcase.gsub(' ', '-')}.md", 'w') do |file|
      file.puts Kramdown::Document.new(markdown_content).to_kramdown
    end
  end
end

# Start scraping and converting from the main URL
scrape_and_convert_articles('https://learnc.info/c/')