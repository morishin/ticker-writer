require 'json'
require 'rest-client'
require 'retryable'

class Task
  DB_HOST = ENV['DB_HOST']
  DB_PORT = ENV['DB_PORT']
  DB_NAME = ENV['DB_NAME']
  DB_USER = ENV['DB_USER']
  DB_PASS = ENV['DB_PASS']
  SLACK_URL = ENV['SLACK_WEBHOOK_URL']

  COINCHECK_API_URL = 'https://coincheck.jp/api/ticker'

  def self.run
    required_vars = [DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS]
    if required_vars.include?(nil) || required_vars.include?("")
      raise "These environment variables must be set: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS"
    end

    begin
      response = Retryable.retryable(tries: 3) do
        RestClient.get COINCHECK_API_URL
      end
    rescue => error
      notify_error_to_slack(error) unless SLACK_URL.nil? || SLACK_URL.empty?
      exit 1
    end

    data = JSON.parse(response)
    last = data['last']

    base_url = "http://#{DB_USER}:#{DB_PASS}@#{DB_HOST}:#{DB_PORT}"

    begin
      Retryable.retryable(tries: 3, sleep: 5.0) do
        RestClient.post "#{base_url}/write?db=ticker", "#{DB_NAME} last=#{last}"
      end
    rescue => error
      notify_error_to_slack(error) unless SLACK_URL.nil? || SLACK_URL.empty?
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
