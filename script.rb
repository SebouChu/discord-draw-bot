require 'bundler/setup'
Bundler.require(:default)
Dotenv.load

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_TOKEN'], prefix: ENV['DISCORD_BOT_CMD_PREFIX'], help_command: false
puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

bot.command(:draw, min_args: 2, max_args: 2, usage: 'draw <message_url> <emoji reaction>') do |event, messageUrl, reaction|
  event.respond "Exporting users who reacted #{reaction} to #{messageUrl} ..."

  messageUrlParts = messageUrl.split('/')
  channelId = messageUrlParts[5]
  messageId = messageUrlParts[6]

  channel = event.server.text_channels.detect { |channel| channel.id.to_s == channelId }
  if channel.nil?
    event.respond "Can't find the channel. Exiting..."
    return
  end

  message = channel.load_message(messageId)
  if message.nil?
    event.respond "Can't find the message. Exiting..."
    return
  end

  users = message.reacted_with(reaction, limit: nil)

  Tempfile.new(['users', '.csv']).tap do |file|
    CSV.open(file, 'wb') do |csv|
      csv << ["id", "username"]
      users.each do |user|
        csv << [user.id, user.username]
      end
    end
    event.channel.send_file(file)
  end
  event.respond "There you go."
end

bot.run