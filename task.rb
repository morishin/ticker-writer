require 'json'
require 'rest-client'
require 'retryable'

class Task
  DB_HOST = ENV['DB_HOST']
  DB_PORT = ENV['DB_PORT']
  SLACK_URL = ENV['SLACK_WEBHOOK_URL']
  API_URL = 'https://coincheck.jp/api/ticker'
  DB_NAME = 'ticker'

  def self.run
    if [DB_HOST, DB_PORT, SLACK_URL].include?(nil)
      raise 'These environment variables must be set: SLACK_WEBHOOK_URL, DB_HOST, DB_PORT'
    end

    begin
      response = Retryable.retryable(tries: 3) do
        RestClient.get API_URL
      end
    rescue => error
      notify_error_to_slack(error)
      exit 1
    end

    data = JSON.parse(response)
    last = data['last']

    base_url = "http://#{DB_HOST}:#{DB_PORT}"

    begin
      RestClient.get "#{base_url}/query", { params: { q: "CREATE DATABASE IF NOT EXISTS #{DB_NAME}" } }
    rescue => error
      notify_error_to_slack(error)
      exit 1
    end

    begin
      Retryable.retryable(tries: 3) do
        RestClient.post "#{base_url}/write?db=ticker", "#{DB_NAME} last=#{last}"
      end
    rescue => error
      notify_error_to_slack(error)
    end
  end

  private

  def self.notify_error_to_slack(error)
    message = {
                username: 'ticker-writer',
                icon_emoji: ':no_good:',
                text: error.to_s,
              }
    Net::HTTP.post_form(URI.parse(SLACK_URL), { 'payload' => message.to_json })
  end
end
