json.response do
  json.partial! 'workfiles/workfile', workfile: @workfile, options: @options
end
