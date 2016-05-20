require "rubygems"
require "bundler/setup"
require "sinatra"
require "pubnub"
require 'httparty'
require File.join(File.dirname(__FILE__), "environment")

configure do
  
  set :pubnub, Pubnub.new(subscribe_key: 'sub-c-a57136cc-9870-11e5-b53d-0619f8945a4f', 
	  					   publish_key: 'pub-c-630fe092-7461-4246-b9ba-a6b201935fb7')

  set :views, "#{File.dirname(__FILE__)}/views"
  set :show_exceptions, :after_handler
end

configure :production, :development do
  enable :logging
end

helpers do
  # add your helpers here
  def send_pubnub(msg, channelNames, timerId)
  	channelNames.each do |name|
  		puts "sending to channel: " + name
	  	settings.pubnub.publish(
	  		channel: name,
	  		message: {:message => {:timerId => timerId}, :type => msg}
	  	) do |e|
	  		# puts e.parsed_response
	  	end
  	end
  end
end

post "/v1/setTimer" do

	seconds = params[:numOfSeconds].to_i
	channelNames = params[:channelNames].split(',')
	timerId = params[:timerId]

	Thread.new {
		sleep seconds
		send_pubnub("Timer Done",channelNames,timerId)
	}

	# if seconds > 30
	# 	Thread.new {
	# 		sleep seconds - 30
	# 		send_pubnub("30 Second Warning",channelNames, timerId)
	# 	}
	# end

end

post "/v1/setAvailabilityTimer/:postId" do

	seconds = params[:numOfSeconds].to_i
	channelNames = params[:channelNames].split(',')
	timerId = params[:timerId]
	postId = params[:postId]

	Thread.new {
		sleep seconds

		# #Orig
		# headers = {"X-Parse-Application-Id" => "EvhQWhNkOQrt9FOkJaEAe3tX5qJDfq7K8NMMnpd8",
		# 		   "X-Parse-REST-API-Key" => "GPHw7mJbToX9Tyw7suXilsbkoUoSKN7wpXuTUqJK"}

		#Rise
		headers = {	"X-Parse-Application-Id" => "LmB0uFwS57tbG9O4JYXvMhe1dBOF0Xmnagio1EhV",
						"X-Parse-REST-API-Key" => "7CG6T7BjtYnnCrjoKqaSqsbY8s8ge6fYCp9z81hY"}

		response = HTTParty.get("https://api.parse.com/1/classes/Posts/#{postId}", :headers => headers);
		postStatus = response.parsed_response["status"]

		if postStatus == 'A'
			puts HTTParty.put("https://api.parse.com/1/classes/Posts/#{postId}", :body => {"status"=>"I"}.to_json, :headers => headers)
			send_pubnub("Timer Done",channelNames,timerId)
		end
	}
end

post "/v1/cancelTimer/:timerId" do 

end