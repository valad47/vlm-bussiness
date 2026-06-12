local tgbot = require_shared("tgbot")
local task = require_shared("task")
local pprint = require_shared("pprint")
local io = require_shared("io")

local userdb = require_shared("userdb")

local function deadinside(update)
      local body = {
           chat_id = update.chat.id,
           business_connection_id = update.business_connection_id,
           message_id = update.message_id
      }
      local now = 1000
      body.text = "DEAD INSIDE"
      tgbot.Method("editMessageText", body)
      body.message_id = nil
      task.__sleep(3)
      while now > 0 do
           body.text = `{now} - 7 = {now - 7}`
           now -= 7
           tgbot.Method("sendMessage", body)
           task.__sleep(.1)
      end
end

local function texts(update, texts)
      local body = {
           chat_id = update.chat.id,
           business_connection_id = update.business_connection_id,
           message_id = update.message_id
      }

      for i,v in texts do
          body.text = v
          if i == 1 then tgbot.Method("editMessagetext", body); body.message_id = nil; continue; end
          tgbot.Method("sendMessage", body)
          --task.__sleep(.1)
      end
end

local function penis(update)
      local body = {
           chat_id = update.chat.id,
           business_connection_id = update.business_connection_id,
           text = "PENIS",
           message_id = update.message_id
      }

      tgbot.Method("editMessageText", body)
      task.__sleep(.1)
      body.text = "PENIS ON"
      tgbot.Method("editMessageText", body)

      task.__sleep(.1)
      body.text = "PENIS ON THE"
      tgbot.Method("editMessageText", body)

      task.__sleep(.1)
      body.text = "PENIS ON THE BEAT"
      tgbot.Method("editMessageText", body)

      task.__sleep(.1)
      body.text = "PENIS ON THE BEAT!!!"
      tgbot.Method("editMessageText", body)
end

local function switch(update)
      if not update.reply_to_message then return end
      if update.reply_to_message.from.id ~= update.from.id then return end
      local text_original = update.reply_to_message.text
      local text_switch = string.split(update.text, " ")
      table.remove(text_switch, 1)
      text_switch = table.concat(text_switch, " ")

      local context = false

      tgbot.Method("deleteBusinessMessages", {
             business_connection_id = update.business_connection_id,
             message_ids = {update.message_id}
      })

      while true do
            tgbot.Method("EditMessageText", {
                  chat_id = update.chat.id,
                  business_connection_id = update.business_connection_id,
                  message_id = update.reply_to_message.message_id,
                  text = if context then text_original else text_switch
            })
            context = not context
            task.__sleep(1)
      end
end

local function spam(update)
      local args = string.split(update.text, " ")
      if #args < 3 then return end
      local times = tonumber(args[2])
      table.remove(args, 1)
      table.remove(args, 1)
      local text = table.concat(args, " ")
      tgbot.Method("editMessagetext", {
          chat_id = update.chat.id,
          business_connection_id = update.business_connection_id,
          text = text,
          message_id = update.message_id
      })
      task.__sleep(.5)
      for i=1, times-1 do
          tgbot.Method("sendMessage", {
              chat_id = update.chat.id,
              business_connection_id = update.business_connection_id,
              text = text
          })
          task.__sleep(.5)
      end
end

local function app(update)
      local args = string.split(update.text, " ")
      if #args < 2 then return end
      --local times = tonumber(args[2])
      table.remove(args, 1)
      local text = ""
      for i=1, #args do
          text = text..args[i].." "
          tgbot.Method("editMessagetext", {
              chat_id = update.chat.id,
              business_connection_id = update.business_connection_id,
              text = text,
              message_id = update.message_id
          })
          task.__sleep(1)
      end
end

local function del(update)
    local args = string.split(update.text, " ")
    local num = if #args == 2 then (tonumber(args[2]) or 0) + 1 else 1
    local business_id = userdb.connections[update.business_connection_id]

    local delete_ids = {{update.message_id}}
    local epoch = update.message_id
    for i = 2, num do
        delete_ids[(i%100) + 1] = delete_ids[(i%100) + 1] or {}
        local message = nil
        while epoch > 1 and (not message or message.deleted) do
            epoch -= 1
            message = userdb.chats[business_id][update.chat.id][epoch]
        end
        message.deleted = true
        table.insert(delete_ids[(i%100) + 1], epoch)
    end
    for i,v in delete_ids do
        tgbot.Method("deleteBusinessMessages", {
             business_connection_id = update.business_connection_id,
             message_ids = v
        })
    end
end

local function download(update)
    local args = string.split(update.text, " ")
    local url = if #args == 2 and string.find(args[2], "https://") then
                    args[2]
                elseif update.reply_to_message
                   and string.find(update.reply_to_message.text, "https://") then
                    update.reply_to_message.text
                else nil

     if not url then
         tgbot.Method("editMessagetext", {
              chat_id = update.chat.id,
              business_connection_id = update.business_connection_id,
              text = `Usage: {args[1]} [url]\nOr reply .dl to message with video url`,
              message_id = update.message_id
          })
          return
     end

     local uuid = `{update.chat.id}-{update.message_id}-{update.from.id}`

     tgbot.Method("editMessagetext", {
              chat_id = update.chat.id,
              business_connection_id = update.business_connection_id,
              text = `Downloading video...`,
              message_id = update.message_id
          })

     local ret = io.shcall(`yt-dlp --max-filesize 50.0M --no-warnings -t mp4 --add-metadata --no-playlist -o {uuid}.mp4 {url}`)
     local message = tgbot.MethodFile("sendVideo", {
         chat_id = update.chat.id,
         business_connection_id = update.business_connection_id
         }, {video = `{uuid}.mp4`})
     if not message then
         tgbot.Method("editMessageText", {
             business_connection_id = update.business_connection_id,
             chat_id = update.chat.id,
             message_id = update.message_id,
             text = "Failed to download video, it may be above 50M, or try again later"
         })
     else
         tgbot.Method("DeleteBusinessMessages", {
             business_connection_id = update.business_connection_id,
             message_ids = { update.message_id }
         })
     end
     
     io.DeleteFile(`{uuid}.mp4`)
end

local mute = require_shared("mute")

local commands = {
      [".penis"] = penis,
      [".di"] = deadinside,
      [".switch"] = switch,
      [".spam"] = spam,
      [".спам"] = spam,
      [".app"] = app,
      [".mute"] = mute.mute,
      [".unmute"] = mute.unmute,
      [".del"] = del,
      [".dl"] = download,
      [".trans"] = require_shared("translate")
}

local function do_command(update)
      local args = update.text
      if not args then return false end
      local cmd = commands[string.split(args, " ")[1]]

      args = args:split("\n")
      if args[#args] == "@" then cmd = ps end
      if not cmd then return false end
      if cmd == mute.mute or cmd == mute.unmute then cmd(update) return true end
      task.truethread(function() cmd(update) end)
      return true
end

return do_command