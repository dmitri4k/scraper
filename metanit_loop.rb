require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'net/http'

# Proxy and User-Agent setup
PROXIES = [
  { addr: 'proxy1.address.com', port: 8080, user: 'user1', pass: 'pass1' },
  # Add more proxies as needed
].freeze

USER_AGENTS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15",
  # Add more user agents as needed
].freeze

# Function to rotate proxies and user-agents
def open_with_proxy(url)
  proxy = PROXIES.sample
  user_agent = USER_AGENTS.sample

  open(url, proxy: "http://#{proxy[:user]}:#{proxy[:pass]}@#{proxy[:addr]}:#{proxy[:port]}", "User-Agent" => user_agent)
end

# Main scraping logic
def scrape_article(url)
  begin
    document = Nokogiri::HTML(open_with_proxy(url))
    # Process the document, e.g., extract title, content
    {
      title: document.at_css('title')&.text,
      content: document.at_css('body')&.text.strip[0..200] # Just an example to grab a piece of the content
    }
  rescue => e
    puts "Error scraping #{url}: #{e}"
    nil
  end
end

## -------------------------------------------------------------------------

def setup_proxy
  URI.parse("http://#{PROXY_ADDR}:#{PROXY_PORT}")
end

def open_with_proxy(url, proxy_uri)
  URI.open(url, proxy: proxy_uri, http_basic_authentication: [PROXY_USER, PROXY_PASS]).read
end

# Assuming download_file and generate_markdown methods are defined as before

def scrape_and_convert_with_proxy(url, proxy_uri)
  puts "Scraping URL: #{url}"

  html_content = open_with_proxy(url, proxy_uri)
  page = Nokogiri::HTML(html_content)

  # Assuming the selection and processing logic is correct for the specific page structure
  page.css('li > p > a').each do |link|
    # Your existing processing logic
    # ...
    puts "Article '#{article_title}' has been scraped and converted to Markdown."
  end
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end

def loop_scrape(urls)
  proxy_uri = setup_proxy

  urls.each do |url|
    scrape_and_convert_with_proxy(url, proxy_uri)
    sleep(rand(1..5)) # Be polite and avoid hammering the server with requests
  end
end

# Main
$site = 'https://metanit.com/c/tutorial/'
article_paths = ['1.1', '1.2'] # As example article paths to be appended to $site for full URLs
urls = article_paths.map { |path| "#{$site}#{path}" }

loop_scrape(urls)