require "time"
require "cgi"
require "yaml"
require "logger"
Bundler.require

Dotenv.load

def main
  loop do
    logger.info("Loading a song")
    song = load_song
    logger.info("Loaded a song: #{song.join(" ")}")
    
    router = WHR1166DHP3.new

    logger.info("Logging into router")
    router.login
    logger.info("Logged into router")

    logger.info("Updating G SSIDs")
    router.update_g(["\u200B" + song[0], "\u200C" + song[1]])
    logger.info("Updated G SSIDs")

    logger.info("Logging into router")
    router.login
    logger.info("Logged into router")

    logger.info("Updating A SSIDs")
    if song.size == 3
      router.update_a(["\u200D" + song[2], nil])
    else
      router.update_a(["\u200D" + song[2], "\u200E" + song[3]])
    end
    logger.info("Updated A SSIDs")

    logger.info("Sleeping")
    sleep 60 * 60
    logger.info("Slept")
  end
end

def logger
  @logger ||= Logger.new(STDOUT)
end

def load_song
  songs = YAML.load(File.read("songs.yaml"))
  songs.sample
end

class WHR1166DHP3
  BUFFALO_IP = ENV["BUFFALO_IP"]
  BUFFALO_USERNAME = ENV["BUFFALO_USERNAME"]
  BUFFALO_PASSWORD = ENV["BUFFALO_PASSWORD"]

  def initialize
    #agent.agent.http.debug_output = STDERR
  end

  def agent
    @agent ||= Mechanize.new
  end
  
  def login
    page = agent.get("http://#{BUFFALO_IP}/login.html")
    form = page.forms.first
    form.field_with(name: "nosave_Username").value = BUFFALO_USERNAME
    form.field_with(name: "nosave_Password").value = BUFFALO_PASSWORD
    form.submit
  end

  def update_g(names)
    update(
      names: names,
      path: "wlan_basic.html",
      suffix: "",
    )
  end

  def update_a(names)
    update(
      names: names,
      path: "wlan_multi_5g.html",
      suffix: "_5g",
    )
  end
  
  def update(options)
    path = options[:path]
    suffix = options[:suffix]
    names = options[:names]

    page = agent.get("http://#{BUFFALO_IP}/#{path}")
    page.encoding ="utf-8"
    session_num = page.search("input[name='nosave_session_num']").first.attr("value")
    form = page.forms.first
    form.field_with(name: "WIFISsid1Enable#{suffix}").value = "1"
    form.field_with(name: "WIFISsid1#{suffix}").value = names[0]
    if names.size == 2
      form.field_with(name: "WIFISsid3Enable#{suffix}").value = "1"
      form.field_with(name: "WIFISsid3#{suffix}").value = names[1]
    else
      form.field_with(name: "WIFISsid3Enable#{suffix}").value = "0"
    end
    form.add_field!("nosave_session_num", session_num)
    form.radiobutton_with(name: "nosave_usessid1", value: "0").check
    form.radiobutton_with(name: "nosave_usessid3", value: "0").check
    form.submit
  end
end

main
