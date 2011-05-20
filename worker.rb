require 'simple_worker'
require 'json'
require 'net/http'

SimpleWorker.configure do |config|
  config.access_key = 'YOUR_SIMPLE_WORKER_KEY'
  config.secret_key = 'YOUR_SIMPLE_WORKER_SECRET'
end

#limit the index size
MAXDOCS = 25000

class MyWorker < SimpleWorker::Base
  merge_gem 'faraday-stack', :require=>'faraday_stack'
  merge_gem 'indextank'
  def run
    plixi_url='http://api.plixi.com/api/tpapi.svc/json/photos?getuser=true'

    api = IndexTank::Client.new 'YOUR_INDEXTANK_API_URL'
    index = api.indexes 'YOUR_INDEXTANK_INDEX'


    interval = 10
    time_first = 0
    seq = 0
    lastHighest = 0

    while true
      begin
        photos = JSON.parse(Net::HTTP.get_response(URI.parse(plixi_url)).body)
        count, list = photos['Count'], photos['List']

        time_last = Integer(list.last['UploadDate'])

        #adjust the interval for minimal or no overlap
        #we may lose some, but this is a demo.
        if time_last < time_first
          interval += 1
        end
        if time_last > time_first and interval > 0
          interval -= 1
        end

        time_first = Integer(list[0]['UploadDate'])
        highestSeen = Integer(list[0]['GdAlias'])
        list.each do |p|
          u = p['User']
          #only index photos that come with some text
          if p.has_key?('Message')
            id = p['GdAlias']
            #avoid duplicates from overlap
            if Integer(id) < lastHighest
              print 'dropping duplicate:', id
              next 
            end
            text = p['Message']
            timestamp = Integer(p['UploadDate'])
            screen_name = u['ScreenName']
            thumbnail_url = p['ThumbnailUrl']
            index.document(seq.to_s).add({:plixi_id => id, 
              :text => text, 
              :title => text, 
              :timestamp => timestamp, 
              :screen_name => screen_name, 
              :thumbnail => thumbnail_url, 
              :url => 'http://plixi.com/p/' + id})
              printf "%s,%s,%s\n", id, screen_name, text
              seq = (seq + 1) % MAXDOCS
              STDOUT.flush
            end
          end
        rescue Exception => e
          puts e
        end
        lastHighest = highestSeen
        sleep interval
      end
    end
  end

  puts 'starting fetcher'
  worker = MyWorker.new
  worker.queue()
  puts 'running'
