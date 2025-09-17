local time = os.clock()

local tgbot = require_shared("tgbot")
local task = require_shared("task")
local pprint = require_shared("pprint")
local io = require_shared("io")
local cbor = require_shared("cbor")
local xor = require_shared("xor")

local user_commands = require_shared("user_commands")
local mute = require_shared("mute")

local token = io.ReadFile(".token")

tgbot.SetToken(token)
tgbot._AsyncNoRet()

local owner_chat = 829586530

local chats = {}
local connections = {}
local settings = {}

local function save_connections()
      io.WriteFile(".connections", cbor.encode(connections))
end

local function restore_connections()
      connections = cbor.decode(io.ReadFile(".connections"))
end

local function save_settings()
      io.WriteFile(".settings", cbor.encode(settings))
end

local function business_connection(update)
      connections[update.id] = if update.is_enabled then update.user_chat_id else nil
      save_connections()
      tgbot.SendMessage(owner_chat, `User [{update.user.first_name}](tg://user?id={update.user.id}) {if update.is_enabled then "" else "dis"}connected bot\\!`, "MarkdownV2")
end

local function deleted_message(update)
      local business_id = connections[update.business_connection_id]

      if not settings[business_id] then settings[business_id] = {
          edited_message = true,
          deleted_message = true
      } end
      save_settings()

      if not settings[business_id].deleted_message then return end

      for i, v in update.message_ids do
          if chats[business_id] and chats[business_id][update.chat.id] and chats[business_id][update.chat.id][v] then
              local message = chats[business_id][update.chat.id][v]
              tgbot.SendMessage(connections[update.business_connection_id], `New deleted message from <a href="tg://user?id={message.id}">{message.first_name}</a> (@{message.username}):\n{message.text}`, "HTML")
              if message.audio then
                 tgbot.Method("sendAudio", {chat_id = connections[update.business_connection_id], audio = message.audio})
              end
              if message.photo then
                 tgbot.Method("sendPhoto", {chat_id = connections[update.business_connection_id], photo = message.photo})
              end
              if message.document then
                 tgbot.Method("sendDocument", {chat_id = connections[update.business_connection_id], document = message.document})
              end
              if message.voice then
                 tgbot.Method("sendVoice", {chat_id = connections[update.business_connection_id], voice = message.voice})
              end
              if message.video then
                 tgbot.Method("sendVideo", {chat_id = connections[update.business_connection_id], video = message.video})
              end
              if message.sticker then
                 tgbot.Method("sendSticker", {chat_id = connections[update.business_connection_id], sticker = message.sticker})
              end
              if message.video_note then
                 tgbot.Method("sendVideoNote", {chat_id = connections[update.business_connection_id], video_note = message.video_note})
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

      if not chats[business_id] then chats[business_id] = {} end
      if not chats[business_id][update.chat.id] then chats[business_id][update.chat.id] = {} end
      chats[business_id][update.chat.id][update.message_id] = {
                                                                                    text = update.text,
                                                                                    username = update.from.username,
                                                                                    first_name = update.from.username,
                                                                                    id = update.from.id
                                                                                }

      if update.photo then
          for i,v in update.photo do
              chats[business_id][update.chat.id][update.message_id].photo = v.file_id
          end
      end
      if update.audio then
          local v = update.audio
              chats[business_id][update.chat.id][update.message_id].audio = v.file_id
      end
      if update.document then
          local v = update.document
              chats[business_id][update.chat.id][update.message_id].document = v.file_id
      end
      if update.voice then
          local v = update.voice
              chats[business_id][update.chat.id][update.message_id].voice = v.file_id
      end
      if update.video then
          local v = update.video
              chats[business_id][update.chat.id][update.message_id].video = v.file_id
      end
      if update.sticker then
          local v = update.sticker
              chats[business_id][update.chat.id][update.message_id].sticker = v.file_id
      end
      if update.video_note then
          local v = update.video_note
              chats[business_id][update.chat.id][update.message_id].video_note = v.file_id
      end
end

local function message_edited(update)
      if update.location then return end
      if update.message and (update.message.gift or update.message.unique_gift) then return end
      local business_id = connections[update.business_connection_id]
      if not settings[business_id] then settings[business_id] = {
          edited_message = true,
          deleted_message = true
      } end
      save_settings()

      local message = if chats[business_id] then if chats[business_id][update.chat.id] then chats[business_id][update.chat.id][update.message_id] or {} else {} else {}
      new_message(update)
      
      if settings[business_id].edited_message then
          tgbot.SendMessage(business_id, `Edited message from <a href="tg://user?id={update.id}">{update.from.first_name}</a> (@{update.from.username}):\nBefore:\n{message.text}\n\nAfter:\n{update.text}`, "HTML")
      end
end

tgbot.AddCommand("start", function(update)
    tgbot.SendMessage(update.message.chat.id, `Welcome to *Dmessages*\\.\n\n*Dmessages* is a powerful bot for saving deleted and edited telegram messages in private chats\\.\n\nTo connect bot, you *must* have telegram premium, in order to access telegram business features\\.\nNext, navigate to telegram's\n*\\[Setting\\] \\-\\> \\[Telegram Business\\] \\-\\> \\[Chatbots\\]*\nand paste link \`t.me/valad47_business_bot\` here\\.\n\nTo have access to user commands, enable *\\[Reply to Messages\\]* option\\.\n\nMore info about user commands: /help\n\n_Powered by [vlm](https://github.com/valad47/vlm)_`, "MarkdownV2")
end, "Welcome message of the bot")

tgbot.AddCommand("help", function(update)
    tgbot.SendMessage(update.message.chat.id, `User commands list\n`..
    `To use commands, just type them in private chats`..
    `\n`..
    `\n`..
    `**>\`.penis\` \\- PENIS ON THE BEAT\\!\\!\\!\n`..
    `>\`.di\` \\- 1000\\-7 message sequence \\(May be slowed down by telegram restrictions\\)\n`..
    `>\`.pp\` \\- preset message sequence\n`..
    `>\`.spam \\[num\\] \\[msg\\]\` \\- send \\[msg\\] message \\[num\\] times\n`..
    `>\`.app \\[msg\\]\` \\- send \\[msg\\] word by word with delay in 1 seconds||`
    , "MarkdownV2")
end, "User commands list")


local function make_keyboard(user_id)
      if not settings[user_id] then settings[user_id] = {
          edited_message = true,
          deleted_message = true
      } end
      save_settings()
      
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

task.spawn(function()
    while task.wait(300) do
        task.truethread(function()
          mute.save()
          io.WriteFile(".chat_save", xor(cbor.encode(chats), token))
        end)
    end
end)

tgbot.AddCommand("save", function(update)
     if update.message.from.id ~= 829586530 then return end
     task.truethread(function()
         local time = task.__time()
         io.WriteFile(".chat_save", xor(cbor.encode(chats), token))
         tgbot.SendMessage(update.message.chat.id, ("Saved chats in %.3f seconds"):format(task.__time() - time))
     end)
end, "[Developer command, you don't have access]")

restore_connections()
chats = cbor.decode(xor(io.ReadFile(".chat_save"), token))
local ss = io.ReadFile(".settings")
settings = if ss and ss ~= "" then cbor.decode(ss) else {}

print(("Loaded bot in %.3f seconds"):format(os.clock() - time))
tgbot.StartLoop()
