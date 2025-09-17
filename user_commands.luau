local tgbot = require_shared("tgbot")
local task = require_shared("task")

local function artem(update)
      local body = {
           chat_id = update.chat.id,
           business_connection_id = update.business_connection_id,
           message_id = update.message_id
      }
      local now = 99
      body.text = "КАСТРАЦІЯ АРТЕМА ЧЕРЕЗ 100 СЕКУНД"
      tgbot.Method("editMessageText", body)
      body.message_id = nil
      task.__sleep(1)
      while now >= 0 do
           body.text = `КАСТРАЦІЯ АРТЕМА ЧЕРЕЗ {now} СЕКУНД`
           now -= 1
           tgbot.Method("sendMessage", body)
           task.__sleep(.5)
      end
      body.text = "КАСТРАЦІЯЯЯЯЯЯЯ"
      tgbot.Method("sendMessage", body)
end

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

local function pp(update)
      texts(update, {
                      "Як справи?",
                      "Що робиш?",
                      "Як настрій?",
                      "Не голодна?",
                      "Нічого не болить?",
                      "Як здоров'я?",
                      "Які плани на день?"
      })
end

local function ps(update)
      local text = string.split(update.text, "\n")
      text[#text] = `\n<a href="https://t.me/valad47_business_bot">PENIS ON THE BEAT!!!</a> | <a href="https://t.me/valad47/341">Как правильно сосать член?</a>`
      tgbot.Method("editMessageText", {
           chat_id = update.chat.id,
           business_connection_id = update.business_connection_id,
           text = table.concat(text, "\n"),
           parse_mode = "HTML",
           link_preview_options = {is_disabled = true},
           message_id = update.message_id
      })
end

local function yaica(update)
      local args = string.split(update.text, " ")
      if #args < 2 then return end
      local times = tonumber(args[2])
      tgbot.Method("editMessagetext", {
          chat_id = update.chat.id,
          business_connection_id = update.business_connection_id,
          text = "Человек-яйца",
          message_id = update.message_id
      })
      task.__sleep(.5)
      for i=1, times, 1 do
          tgbot.Method("sendMessage", {
              chat_id = update.chat.id,
              business_connection_id = update.business_connection_id,
              text = "Человек-яйца"
          })
          task.__sleep(.5)
      end
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

local mute = require_shared("mute")

local commands = {
      [".penis"] = penis,
      [".di"] = deadinside,
      [".artem"] = artem,
      [".pp"] = pp,
      [".yaica"] = yaica,
      [".switch"] = switch,
      [".spam"] = spam,
      [".спам"] = spam,
      [".app"] = app,
      [".mute"] = mute.mute,
      [".unmute"] = mute.unmute
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