local tgbot = require_shared("tgbot")
local io = require_shared("io")
local cbor = require_shared("cbor")

local MUTE_FILE = ".mute_users"

local mute = {}

local users = io.ReadFile(MUTE_FILE)
      users = if users then cbor.decode(users) else {}

function mute.new_message(update, business_id): boolean
    local from_id = update.from.id
    local chat_id = update.chat.id
    if from_id == business_id then return true end
    if not (users[business_id] or {})[chat_id] then
        return true
    end
    tgbot.Method("deleteBusinessMessages", {
        business_connection_id = update.business_connection_id,
        message_ids = {update.message_id}
    })
    return false
end

function mute.mute(update)
    local business_id = update.from.id
    users[business_id] = users[business_id] or {}
    users[business_id][update.chat.id] = true
    tgbot.Method("EditMessageText", {
                  chat_id = update.chat.id,
                  business_connection_id = update.business_connection_id,
                  message_id = update.message_id,
                  text = "Помолчи."
            })
end

function mute.unmute(update)
    local business_id = update.from.id
    users[business_id] = users[business_id] or {}
    users[business_id][update.chat.id] = nil
    tgbot.Method("EditMessageText", {
                  chat_id = update.chat.id,
                  business_connection_id = update.business_connection_id,
                  message_id = update.message_id,
                  text = "Можешь говорить."
            })
end

function mute.save()
    io.WriteFile(MUTE_FILE, cbor.encode(users))
end

return mute