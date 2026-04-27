local tgbot = require_shared("tgbot")

local translations = {}

translations.en = {
    q = "й",
    w = "ц",
    e = "у",
    r = "к",
    t = "е",
    y = "н",
    u = "г",
    i = "ш",
    o = "щ",
    p = "з",
    ["["] = "х",
    ["]"] = "ї",
    a = "ф",
    s = "і",
    d = "в",
    f = "а",
    g = "п",
    h = "р",
    j = "о",
    k = "л",
    l = "д",
    [";"] = "ж",
    ["'"] = "є",
    z = "я",
    x = "ч",
    c = "с",
    v = "м",
    b = "и",
    n = "т",
    m = "ь",
    [","] = "б",
    ["."] = "ю",
    ["/"] = ".",
    ['Q'] = 'Й',
    ['W'] = 'Ц',
    ['E'] = 'У',
    ['R'] = 'К',
    ['T'] = 'Е',
    ['Y'] = 'Н',
    ['U'] = 'Г',
    ['I'] = 'Ш',
    ['O'] = 'Щ',
    ['P'] = 'З',
    ['{'] = 'Х',
    ['}'] = 'Ї',
    ['A'] = 'Ф',
    ['S'] = 'І',
    ['D'] = 'В',
    ['F'] = 'А',
    ['G'] = 'П',
    ['H'] = 'Р',
    ['J'] = 'О',
    ['K'] = 'Л',
    ['L'] = 'Д',
    [':'] = 'Ж',
    ['"'] = 'Є',
    ['Z'] = 'Я',
    ['X'] = 'Ч',
    ['C'] = 'С',
    ['V'] = 'М',
    ['B'] = 'И',
    ['N'] = 'Т',
    ['M'] = 'Ь',
    ['<'] = 'Б',
    ['>'] = 'Ю',
    ['?'] = ',',
}

translations.ua = {

}

local function trans(update)
    local args = string.split(update.text, " ")
    local trans = translations[args[2] or "en"] or translations.en
    local result = ""
    for i,v in string.split(update.reply_to_message.text, "") do
        result = result .. (trans[v] or v)
    end

    tgbot.Method("deleteBusinessMessages", {
        business_connection_id = update.business_connection_id,
        message_ids = {update.message_id}
    })
    tgbot.Method("editMessageText", {
        chat_id = update.chat.id,
        business_connection_id = update.business_connection_id,
        message_id = update.reply_to_message.message_id,
        text = result
    })
end

return trans
