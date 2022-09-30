
local available_languages = {
    'en', 'sv',
}

local selected_lang = 'en'

function set_selected_language(index)
    selected_lang = available_languages[index]
end

local text_data = {
    en = {
        language = 'Language',
        english = 'English',
        swedish = 'Swedish',
    },
    sv = {
        language = 'Språk',
        english = 'Engelska',
        swedish = 'Svenska',
    },
}

function localize(text_id)
    return text_data[selected_lang][text_id] or '[' .. text_id .. ']'
end