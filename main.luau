local time = os.clock()

local tgbot = require_shared("tgbot")
local task = require_shared("task")
local pprint = require_shared("pprint")

local user_commands = require_shared("user_commands")
local mute = require_shared("mute")

local userdb = require_shared("userdb")

local chats = userdb.chats
local connections = userdb.connections
local settings = userdb.settings

tgbot._AsyncNoRet()

local owner_chat = 829586530

local function business_connection(update)
      connections[update.id] = if update.is_enabled then update.user_chat_id else nil
      tgbot.SendMessage(owner_chat, `User [{update.user.first_name}](tg://user?id={update.user.id}) {if update.is_enabled then "" else "dis"}connected bot\\!`, "MarkdownV2")
end

local function deleted_message(update)
      local business_id = connections[update.business_connection_id]

      if not settings[business_id] then settings[business_id] = {
          edited_message = true,
          deleted_message = true
      } end

      if not settings[business_id].deleted_message then return end

      for i, v in update.message_ids do
          local message = chats[business_id][update.chat.id][v]
          if message then
              message.deleted = true
              tgbot.SendMessage(connections[update.business_connection_id], `New deleted message from <a href="tg://user?id={message.from_id}">{message.first_name}</a> (@{message.username}):\n{message.text}`, "HTML")

              local methods = {
                  ["audio"] = "sendAudio",
                  ["photo"] = "sendPhoto",
                  ["document"] = "sendDocument",
                  ["voice"] = "sendVoice",
                  ["video"] = "sendVideo",
                  ["sticker"] = "sendSticker",
                  ["video_note"] = "sendVideoNote"
              }

              local media_type = message.media_type or ""
              local method = methods[media_type]
              if method then
                  local data = {
                     chat_id = connections[update.business_connection_id]
                  }
                  data[media_type] = message.media_key
                  tgbot.Method(method, data)
              end
          end
      end
end

local function new_message(update)
      local business_id = connections[update.business_connection_id]
      if not mute.new_message(update, business_id) then return end
      if business_id == update.from.id then
          if user_commands(update) then return end
      end

      if update.reply_to_message and update.reply_to_message.has_protected_content then
          new_message(update.reply_to_message)
          deleted_message({
              business_connection_id = update.business_connection_id,
              message_ids = {update.reply_to_message.message_id},
              chat = update.reply_to_message.chat
          })
      end

      local new_message = {
                              text = update.text,
                              username = update.from.username,
                              first_name = update.from.username,
                              from_id = update.from.id,
                              date = update.date
      }

      local media = {
          "photo",
          "audio",
          "document",
          "voice",
          "video",
          "sticker",
          "video_note"
      }

      for i,v in media do
          if update[v] then
              new_message.media_type = v
              if v == "photo" then
                  new_message.media_key = update.photo[1].file_id
              else
                  new_message.media_key = update[v].file_id
              end
          end
      end

      chats[business_id][update.chat.id][update.message_id] = new_message
end

local function message_edited(update)
      if update.location then return end
      if update.message and (update.message.gift or update.message.unique_gift) then return end
      local business_id = connections[update.business_connection_id]
      if not settings[business_id] then settings[business_id] = {
          edited_message = true,
          deleted_message = true
      } end

      local message = chats[business_id][update.chat.id][update.message_id]

      if not message then return end

      if settings[business_id].edited_message then
          tgbot.SendMessage(business_id, `Edited message from <a href="tg://user?id={update.id}">{update.from.first_name}</a> (@{update.from.username}):\nBefore:\n{message.text}\n\nAfter:\n{update.text}`, "HTML")
      end
      new_message(update)
end

tgbot.AddCommand("start", function(update)
    tgbot.SendMessage(update.message.chat.id, `Welcome to *Dmessages*\\.\n\n*Dmessages* is a powerful bot for saving deleted and edited telegram messages in private chats\\.\n\nTo connect bot, you *must* have telegram premium, in order to access telegram business features\\.\nNext, navigate to telegram's\n*\\[Setting\\] \\-\\> \\[Telegram Business\\] \\-\\> \\[Chatbots\\]*\nand paste link \`t.me/valad47_business_bot\` here\\.\n\nTo have access to user commands, enable *\\[Reply to Messages\\]* option\\.\n\nMore info about user commands: /help\n\n_Powered by [vlm](https://github.com/valad47/vlm)_`, "MarkdownV2")
end, "Welcome message of the bot")

tgbot.AddCommand("help", function(update)
    tgbot.SendMessage(update.message.chat.id, `User commands list\n`..
    `To use commands, just type them in private chats`..
    `\n`..
    `\n`..
    `**>\`.di\` \\- 1000\\-7 message sequence \\(May be slowed down by telegram restrictions\\)\n`..
    `>\`.pp\` \\- preset message sequence\n`..
    `>\`.spam \\[num\\] \\[msg\\]\` \\- send \\[msg\\] message \\[num\\] times\n`..
    `>\`.mute\` \\- delete all incoming messages from user\n`..
    `>\`.unmute\` \\- stop \`.mute\`\n`..
    `>\`.app \\[msg\\]\` \\- send \\[msg\\] word by word with delay in 1 seconds||`
    , "MarkdownV2")
end, "User commands list")


local function make_keyboard(user_id)
      if not settings[user_id] then settings[user_id] = {
          edited_message = true,
          deleted_message = true
      } end
      
      return {inline_keyboard = {
            {
                {
                    text = `Edited message {if settings[user_id].edited_message then "✅" else "🚫"}`,
                    callback_data = "edited_message"
                }
            },
            {
                {
                    text = `Deleted message {if settings[user_id].deleted_message then "✅" else "🚫"}`,
                    callback_data = "deleted_message"
                }
            }
        } }
end

tgbot.AddCommand("settings", function(update)
    tgbot.SendMessage(update.message.chat.id, `Bot settings\n\nToggle which updates should be sent`, nil, nil, make_keyboard(update.message.from.id))
end, "Bot settings")

local function callback_query(update)
      settings[update.from.id][update.data] = not settings[update.from.id][update.data] 
      tgbot.EditMessageText(
             update.message.chat.id,
             update.message.message_id,
             update.message.text,
             nil,
             make_keyboard(update.from.id)
      )
end


local callbacks = {
      business_connection = business_connection,
      deleted_business_messages = deleted_message,
      edited_business_message = message_edited,
      business_message = new_message,
      callback_query = callback_query
}

tgbot.SetTextHandler(function(update)
    for i, v in update do
        (callbacks[i] or function() end)(v)
    end
end)

print(("Loaded bot in %.3f seconds"):format(os.clock() - time))
tgbot.StartLoop()
