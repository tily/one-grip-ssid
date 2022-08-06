require "nokogiri"
require "open-uri"
require "yaml"
require "logger"

URL = "https://www.aozora.gr.jp/cards/000153/files/816_15786.html"

REMOVE_SELECTORS = %w(
  div.metadata div#contents
  div.jisage_1 div.jisage_3 div.jisage_6
  rp rt div.bibliographical_information
  div.notation_notes div#card
)

def main
  logger.info("Loading songs ...")
  songs = fetch_songs
  logger.info("Loaded #{songs.size} songs")

  logger.info("Filtering songs ...")
  songs = filter_songs(songs)
  logger.info("Filtered and now #{songs.size} songs")

  logger.info("Converting songs ...")
  songs = convert_songs(songs)
  logger.info("Converted songs")

  File.write("songs.yaml", YAML.dump(songs))
end

def logger
  @logger ||= Logger.new(STDOUT)
end

def fetch_songs
  doc = Nokogiri::HTML(URI.open(URL))
  REMOVE_SELECTORS.each do |s|
    doc.search(s).remove
  end
  text = doc.content
  text = text.match(/(.+)(東海の小島の磯の白砂に(.+)息きれし児の肌のぬくもり)(.+)/m)[2]
  songs = text.split(/\r\n\r\n/).map do |song_text|
    song_text.split(/\r\n/)
  end
end

def filter_songs(songs)
  songs.reject do |song|
    if song.any? {|l| l.match(/(死|殺)/) }
      logger.info("Rejctging for death: #{song.join(" ")}")
      next true
    end
    if song.count {|l| l.length >= 10 } >= 2
      logger.info("Rejecting for size: #{song.join(" ")}")
    end
  end
end

def convert_songs(songs)
  songs.map do |song|
    result = []
    song.each do |l|
      if l.length >= 10
        x = l.length / 2  
        result << l[0, x]
        result << "　" + l[x, l.length]
      else
        result << l
      end
    end
    result
  end
end

main
