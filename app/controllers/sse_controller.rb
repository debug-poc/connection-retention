class SseController < ApplicationController
  before_action :authenticate_user!, only: :index

  EVENT_STREAM_HEADERS = {
    "content-type" => "text/event-stream",
    "cache-control" => "no-cache",
    "last-modified" => Time.now.httpdate
  }

  def signin
    user = User.order(Arel.sql("RANDOM()")).first
    sign_in(user)
    redirect_to root_path
  end

  def index
    user = Current.user
    user.touch
    body = proc do |stream|
      while true
        stream.write "data: #{Time.now.to_i}\n\n"
        stream.write "data: #{user.updated_at.to_i}\n\n"
        stream.write "data: #{ActiveRecord::Base.connection_pool.stat}\n\n"
        sleep 1
      end
    ensure
      stream.close
    end

    self.response = Rack::Response[200, EVENT_STREAM_HEADERS.dup, body]
  end
end
