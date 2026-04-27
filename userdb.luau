local sqlite = require_shared("sqlite")
local pprint = require_shared("pprint")

local userdb = {}

userdb.connections = {}
userdb.settings = {}

local db = sqlite.open("chats.db")
userdb.db = db

sqlite.exec(db, [[
CREATE TABLE IF NOT EXISTS Connections (
    business_id TEXT,
    user_id REAL
);
]])

sqlite.exec(db, [[
CREATE TABLE IF NOT EXISTS Settings (
    user_id REAL,
    edited_message BOOLEAN,
    deleted_message BOOLEAN,
    PRIMARY KEY (user_id)
);
]])

sqlite.exec(db, [[
CREATE TABLE IF NOT EXISTS Messages (
    message_id REAL,
    chat_id REAL,
    user_id REAL,
    from_id REAL,
    deleted BOOLEAN,
    first_name TEXT,
    username TEXT,
    date REAL,
    text TEXT,
    media_type TEXT,
    media_key TEXT,
    PRIMARY KEY (user_id, chat_id, message_id)
);
]])

-- Build SET clause safely
local function buildSet(data: {}|string, value: number|string|boolean|nil)
    if type(data) ~= "table" then
        return `{data} = ?`, {value}
    end
    
    local parts = {}
    local values = {}

    for k, v in data do
        table.insert(parts, `{k}=?`)
        table.insert(values, v)
    end

    return table.concat(parts, ", "), values
end

-- Build INSERT safely
local function buildInsert(data)
    local columns = {}
    local values = {}
    local dat = {}

    for k, v in data do
        table.insert(columns, k)
        table.insert(values, "?")
        table.insert(dat, v)
    end

    return table.concat(columns, ","), table.concat(values, ","), dat
end

-- Query helpers
local function fetchOne(query)
    local result = sqlite.exec(db, query)
    return result[1]
end

local function fetchAll(query)
    return sqlite.exec(db, query)
end

--[[

    -= Connections Database =-

]]--

userdb.connections = setmetatable({}, {
    __index = function(_, business_id)
        local row = sqlite.prepare_varg(db,
            "SELECT user_id FROM Connections WHERE business_id=?",
            business_id
        )[1]

        return if row then row.user_id else nil
    end,

    __newindex = function(_, business_id, user_id)
        if user_id == nil then
            sqlite.prepare_varg(db, "DELETE FROM Connections WHERE business_id=?", business_id)
            return
        end
        
        sqlite.exec(db, "BEGIN TRANSACTION")
        sqlite.exec(db, string.format(
            "DELETE FROM Connections WHERE user_id=%d",
            user_id
        ))

        sqlite.prepare_varg(db, "INSERT INTO Connections (business_id, user_id) VALUES (?, ?)",
                                business_id, user_id)

        sqlite.exec(db, "COMMIT")
    end
})

--[[

    -= Settings Database =-

]]--

local function SettingsProxy(user_id)
    return setmetatable({}, {
        __index = function(_, key)
            local row = fetchOne(string.format(
                "SELECT %s FROM Settings WHERE user_id=%d",
                key, user_id
            ))
            return if row[key] == 1 then true else false
        end,

        __newindex = function(_, key, value)
            local setClause, setValues = buildSet(key, value)

            sqlite.prepare_varg(db, string.format(
                "UPDATE Settings SET %s WHERE user_id=%d",
                setClause, user_id
            ), table.unpack(setValues))
        end
    })
end

userdb.settings = setmetatable({}, {
    __index = function(_, user_id)
        local row = fetchOne(string.format(
            "SELECT user_id FROM Settings WHERE user_id=%d",
            user_id
        ))

        return if row then SettingsProxy(user_id) else nil
    end,

    __newindex = function(_, user_id, value)
        value.user_id = user_id
            
        local cols, vals, data = buildInsert(value)

        sqlite.prepare_varg(db, string.format(
            "INSERT INTO Settings (%s) VALUES (%s)",
            cols, vals
        ), table.unpack(data))
    end
})

--[[

    -= Messages Database =-

]]--

local function MessageProxy(user_id, chat_id, message_id)
    return setmetatable({}, {
        __index = function(_, key)
            local row = fetchOne(string.format(
                "SELECT %s FROM Messages WHERE user_id=%d AND chat_id=%d AND message_id=%d",
                key, user_id, chat_id, message_id
            ))
            return row[key]
        end,

        __newindex = function(_, key, value)
            local setClause, setValues = buildSet(key, value)

            sqlite.prepare_varg(db, string.format(
                "UPDATE Messages SET %s WHERE user_id=%d AND chat_id=%d AND message_id=%d",
                setClause, user_id, chat_id, message_id
            ), table.unpack(setValues))
        end
    })
end

local function ChatProxy(user_id, chat_id)
    return setmetatable({}, {
        __index = function(_, message_id)
            local row = fetchOne(string.format(
                "SELECT message_id FROM Messages WHERE user_id=%d AND chat_id=%d AND message_id=%d",
                user_id, chat_id, message_id
            ))

            return if row then MessageProxy(user_id, chat_id, message_id) else nil
        end,

        __newindex = function(_, message_id, messageData)
            messageData.user_id = user_id
            messageData.chat_id = chat_id
            messageData.message_id = message_id

            if fetchOne(string.format("SELECT message_id FROM Messages WHERE user_id=%d AND chat_id=%d AND message_id=%d",
                                       user_id, chat_id, message_id)) then
                local setClause, setValues = buildSet(messageData)
                sqlite.prepare_varg(db, string.format(
                    "UPDATE Messages SET %s WHERE user_id=%d AND chat_id=%d AND message_id=%d",
                    setClause, user_id, chat_id, message_id
                ), table.unpack(setValues))
            else
                local cols, vals, data = buildInsert(messageData)
                sqlite.prepare_varg(db, string.format(
                    "INSERT INTO Messages (%s) VALUES (%s)",
                    cols, vals
                ), table.unpack(data))
            end
        end
    })
end

local function UserProxy(user_id)
    return setmetatable({}, {
        __index = function(_, chat_id) return ChatProxy(user_id, chat_id) end
    })
end

userdb.chats = setmetatable({}, {
    __index = function(_, user_id) return UserProxy(user_id) end
})

return userdb