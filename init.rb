require 'json'
require 'rest-client'
require 'retryable'

class Init
  DB_HOST = ENV['DB_HOST']
  DB_PORT = ENV['DB_PORT']
  DB_NAME = ENV['DB_NAME']
  DB_USER = ENV['DB_USER']
  DB_PASS = ENV['DB_PASS']
  DB_RETENTION_DURATION = ENV['DB_RETENTION_DURATION'].to_s.empty? ? "90d" : ENV['DB_RETENTION_DURATION']
  SLACK_URL = ENV['SLACK_WEBHOOK_URL']

  def self.run
    required_vars = [DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS, DB_RETENTION_DURATION]
    if required_vars.include?(nil) || required_vars.include?("")
      raise "These environment variables must be set: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS, DB_RETENTION_DURATION"
    end

    base_url = "http://#{DB_HOST}:#{DB_PORT}"
    begin
      Retryable.retryable(tries: 3, sleep: 5) do
        query = "CREATE USER \"#{DB_USER}\" WITH PASSWORD '#{DB_PASS}' WITH ALL PRIVILEGES"
        RestClient.post "#{base_url}/query", {q: query}
      end
    rescue => error
      notify_error_to_slack(error) unless SLACK_URL.nil? || SLACK_URL.empty?
    end

    begin
      Retryable.retryable(tries: 3, sleep: 5) do
        query = "CREATE DATABASE #{DB_NAME} WITH DURATION #{DB_RETENTION_DURATION}"
        RestClient.post "#{base_url}/query?u=#{DB_USER}&p=#{DB_PASS}", { q: query }
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

Init.run
