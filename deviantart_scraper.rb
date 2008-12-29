#!/usr/bin/env ruby
require 'rubygems'
require 'scrubyt'
require 'open-uri'
require 'progressbar'
require 'pp'

DOWNLOAD_DIR = '/Users/akahn/Pictures/Deviant Art/'
# By default, start from the beginning and process 5 images
PROCESS_START = ARGV[0].to_i || 0
PROCESS_COUNT = ARGV[1].to_i || 5

puts "Getting page locations..."
page_urls = Scrubyt::Extractor.define :agent => :firefox do
  fetch 'http://alexanderkahn.deviantart.com/gallery'
  
  title "//a[@class='t']", :write_text => true do
    page_url 'href', :type => :attribute
  end

end

page_urls = page_urls.to_hash
page_urls = page_urls.slice!(PROCESS_START, PROCESS_COUNT)

photo_urls = []
puts "Getting image locations..."
page_urls.each_with_index do |page_url, i|
  photo_url_progress = ProgressBar.new("Images processed", PROCESS_COUNT, STDIN)
  photo_url = Scrubyt::Extractor.define :agent => :firefox do
    fetch page_url[:page_url]
    click_link "Full View"

    image "//span[@id='zoomed-in']/a/img", :example_type => :xpath do
      image_url 'src', :type => :attribute
    end
  end
  photo_urls << photo_url.to_hash
  photo_url_progress.inc
  puts "Processed image " + (i + 1).to_s

end

# Make these into hashes that I can work with
#photo_urls = photo_urls.to_hash

# Cut down page_urls to be the same length as the image_urls I'm working with
page_urls = page_urls.slice(0, photo_urls.length)

# Bring the photo_urls hash to live in page_url array elements
photos = page_urls.zip(photo_urls)

# Merge the hashes so each array element has a title, a page url and an image url
photos.map! do |a1, a2| 
  a1.merge(a2[0])
end

puts "Downloading images..."
photos.each do |photo|
  url = photo[:image_url]
  filename = photo[:title]

  image = open(url).read
  open(DOWNLOAD_DIR + filename + ".jpg", 'wb') do |file| 
    file.write(image)
  end
  puts "Saved file \"" + filename + "\""
end

